import Foundation
import IOKit
import IOKit.hid
import Domain

/// Finds a supported keyboard and keeps its configuration interface open, following IOKit's arrival and
/// removal notifications where the vendor tools poll.
///
/// - The 1189:8890's interface 1 has no driver; it is opened through IOUSBHost (`USBPipeChannel`).
/// - A 884x keyboard's interface 0 is a HID device, opened through IOKit HID (`HIDDeviceChannel`), as the
///   cross-platform app opens the first HID entry on interface 0.
@MainActor
public final class HardwareConnection: KeyboardConnectionRepository, ChannelProvider {
    private let log: DeviceLogStore
    private let state = StateBroadcaster(ConnectionState.searching)
    private var channel: Channel?
    private var connectedEntry: UInt64?
    private var opening = false
    private var failedEntries: Set<UInt64> = []
    private var notificationPort: IONotificationPortRef?
    private var iterators: [io_iterator_t] = []
    private var askedForAccess = false
    private var permissionPoll: Task<Void, Never>?

    @MainActor private enum Channel {
        case usb(USBPipeChannel)
        case hid(HIDDeviceChannel)

        var reportChannel: any ReportChannel {
            switch self {
            case .usb(let channel): channel
            case .hid(let channel): channel
            }
        }

        func close() {
            switch self {
            case .usb(let channel): channel.close()
            case .hid(let channel): channel.close()
            }
        }
    }

    /// kIOReturnNotPermitted: Input Monitoring is not allowed.
    private static let notPermitted = IOReturn(bitPattern: 0xE000_02E2)

    public init(log: DeviceLogStore) {
        self.log = log
        let port = IONotificationPortCreate(kIOMainPortDefault)
        IONotificationPortSetDispatchQueue(port, .main)
        notificationPort = port
        let context = Unmanaged.passUnretained(self).toOpaque()
        // A HID driver attaches after its interface appears, so HID devices are watched as well.
        for (type, serviceClass) in [
            (kIOFirstMatchNotification, "IOUSBHostInterface"), (kIOTerminatedNotification, "IOUSBHostInterface"),
            (kIOFirstMatchNotification, "IOHIDDevice"), (kIOTerminatedNotification, "IOHIDDevice"),
        ] {
            var iterator: io_iterator_t = 0
            IOServiceAddMatchingNotification(port, type, IOServiceMatching(serviceClass), { context, iterator in
                HardwareConnection.drain(iterator)
                guard let context else { return }
                let owner = Unmanaged<HardwareConnection>.fromOpaque(context).takeUnretainedValue()
                MainActor.assumeIsolated { owner.refresh() }
            }, context, &iterator)
            Self.drain(iterator)  // arms the notification
            iterators.append(iterator)
        }
        refresh()
    }

    // MARK: - KeyboardConnectionRepository

    public func connectionStates() async -> AsyncStream<ConnectionState> {
        state.stream()
    }

    public func retry() async {
        failedEntries.removeAll()
        if state.value.keyboard == nil { setState(.searching) }
        refresh()
    }

    var openChannel: (any ReportChannel)? { channel?.reportChannel }

    private func setState(_ new: ConnectionState) {
        guard new != state.value else { return }
        switch new {
        case .searching: log.append(.event(.searching))
        case .connected(let keyboard): log.append(.event(.connected(keyboard.usb, interface: keyboard.interfaceNumber)))
        case .needsPermission: log.append(.event(.needsPermission))
        case .openFailed(let code): log.append(.event(.openFailed(code: code)))
        }
        state.set(new)
    }

    // MARK: - Discovery

    /// A place to write the configuration.
    private struct Candidate: Sendable {
        enum Kind: Sendable { case usb, hid }
        let kind: Kind
        let service: io_service_t
        let entry: UInt64
        let usb: USBIdentity
        let family: KeyboardFamily
        let interfaceNumber: Int?
    }

    private func refresh() {
        let candidates = Self.candidates()
        defer { candidates.forEach { IOObjectRelease($0.service) } }
        let present = Set(candidates.map(\.entry))
        failedEntries.formIntersection(present)

        if let connectedEntry {
            if !present.contains(connectedEntry) { disconnect() }
            return
        }
        guard !opening else { return }
        guard let candidate = candidates.first(where: { !failedEntries.contains($0.entry) }) else {
            // A failure stays on screen while that keyboard is still plugged in.
            switch state.value {
            case .needsPermission, .openFailed: if !present.isEmpty { return }
            default: break
            }
            setState(.searching)
            return
        }
        switch candidate.kind {
        case .usb: openUSB(candidate)
        case .hid: openHID(candidate)
        }
    }

    /// Opening an interface over USB waits for its drivers to settle and sends a control request, so it
    /// runs off the main thread.
    private func openUSB(_ candidate: Candidate) {
        opening = true
        IOObjectRetain(candidate.service)
        let service = candidate.service
        Task { [weak self] in
            let result = await Self.openUSBOffMain(service)
            self?.finishOpeningUSB(candidate, result)
            IOObjectRelease(service)
        }
    }

    nonisolated private static func openUSBOffMain(_ service: io_service_t) async -> Result<PipeWriter.Opened, USBPipeChannel.Failure> {
        let box = UncheckedBox(service)
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Taking an interface before its driver attaches would keep that driver out — on an input
                // interface, the keyboard would stop typing. Wait for matching to finish, then look again.
                var timeout = mach_timespec_t(tv_sec: 2, tv_nsec: 0)
                IOServiceWaitQuiet(box.value, &timeout)
                guard !hasDriver(box.value) else {
                    continuation.resume(returning: .failure(.notConfiguration))
                    return
                }
                continuation.resume(returning: USBPipeChannel.open(box.value))
            }
        }
    }

    private func finishOpeningUSB(_ candidate: Candidate, _ result: Result<PipeWriter.Opened, USBPipeChannel.Failure>) {
        opening = false
        switch result {
        case .success(let opened):
            let channel = USBPipeChannel.make(opened)
            var details = Self.deviceDetails(candidate.service)
            details?.maxPower = opened.maxPower
            connected(candidate, .usb(channel), keyboard: ConnectedKeyboard(
                usb: candidate.usb, family: candidate.family, interfaceNumber: opened.interfaceNumber,
                channel: .usb(outEndpoint: opened.outEndpoint), reportID: channel.framing.reportID,
                reportLength: channel.framing.length, details: details))
        case .failure(.notConfiguration):
            failedEntries.insert(candidate.entry)
            setState(.searching)
        case .failure(.failed(let code)):
            failedEntries.insert(candidate.entry)
            setState(.openFailed(code: code))
        }
        refresh()  // the keyboard may have gone while it was opening
    }

    private func openHID(_ candidate: Candidate) {
        guard let device = IOHIDDeviceCreate(kCFAllocatorDefault, candidate.service) else {
            failedEntries.insert(candidate.entry)
            setState(.openFailed(code: kIOReturnNotFound))
            return
        }
        let log = log
        let channel: HIDDeviceChannel
        do {
            channel = try HIDDeviceChannel.open(device, received: { log.append(.input($0)) })
        } catch where error.status == Self.notPermitted {
            failedEntries.insert(candidate.entry)
            setState(.needsPermission)
            if !askedForAccess {
                askedForAccess = true
                _ = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
            }
            watchForPermission()
            return
        } catch {
            failedEntries.insert(candidate.entry)
            setState(.openFailed(code: error.status))
            return
        }
        permissionPoll?.cancel()
        permissionPoll = nil
        connected(candidate, .hid(channel), keyboard: ConnectedKeyboard(
            usb: candidate.usb, family: candidate.family,
            interfaceNumber: candidate.interfaceNumber ?? candidate.family.configurationInterface,
            channel: .hid, reportID: channel.framing.reportID, reportLength: channel.framing.length,
            details: Self.deviceDetails(candidate.service)))
    }

    private func connected(_ candidate: Candidate, _ channel: Channel, keyboard: ConnectedKeyboard) {
        self.channel = channel
        connectedEntry = candidate.entry
        setState(.connected(keyboard))
    }

    private func disconnect() {
        channel?.close()
        channel = nil
        connectedEntry = nil
        setState(.searching)
        refresh()
    }

    /// Once the user allows Input Monitoring, opens the keyboard without a relaunch.
    private func watchForPermission() {
        guard permissionPoll == nil else { return }
        permissionPoll = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard let self else { return }
                if IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted {
                    permissionPoll = nil
                    await retry()
                    return
                }
            }
        }
    }

    /// Every place a supported keyboard takes its configuration: the 1189:8890's interface 1, then the
    /// HID devices on a 884x keyboard's interface 0 — vendor 1189 before 514C, then in the order the
    /// cross-platform app looks for product IDs.
    nonisolated private static func candidates() -> [Candidate] {
        var found: [Candidate] = []
        forEachService("IOUSBHostInterface") { interface in
            guard let usb = usbIdentity(interface), let family = KeyboardFamily(usb: usb), family == .k8890,
                  registryNumber(interface, "bInterfaceClass") == 3,
                  registryNumber(interface, "bInterfaceSubClass") == 0,
                  let number = registryNumber(interface, "bInterfaceNumber"), number == family.configurationInterface,
                  !hasDriver(interface)
            else { return }
            IOObjectRetain(interface)
            found.append(Candidate(kind: .usb, service: interface, entry: entryID(interface), usb: usb, family: family, interfaceNumber: number))
        }
        var hid: [Candidate] = []
        forEachService("IOHIDDevice") { device in
            guard let usb = usbIdentity(device), let family = KeyboardFamily(usb: usb), family == .k884x else { return }
            let number = interfaceNumber(of: device)
            guard number == nil || number == family.configurationInterface else { return }
            IOObjectRetain(device)
            hid.append(Candidate(kind: .hid, service: device, entry: entryID(device), usb: usb, family: family, interfaceNumber: number))
        }
        let order = KeyboardFamily.supported
        hid.sort { a, b in
            ((a.interfaceNumber == nil ? 1 : 0), order.firstIndex(of: a.usb) ?? 99)
                < ((b.interfaceNumber == nil ? 1 : 0), order.firstIndex(of: b.usb) ?? 99)
        }
        return found + hid
    }

    nonisolated private static func forEachService(_ serviceClass: String, _ body: (io_service_t) -> Void) {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching(serviceClass), &iterator) == KERN_SUCCESS
        else { return }
        defer { IOObjectRelease(iterator) }
        while case let service = IOIteratorNext(iterator), service != 0 {
            body(service)
            IOObjectRelease(service)
        }
    }

    nonisolated private static func usbIdentity(_ service: io_service_t) -> USBIdentity? {
        let vendor = registryNumber(service, "idVendor") ?? registryNumber(service, kIOHIDVendorIDKey)
        let product = registryNumber(service, "idProduct") ?? registryNumber(service, kIOHIDProductIDKey)
        guard let vendor, let product else { return nil }
        return USBIdentity(vendorID: vendor, productID: product)
    }

    /// The USB interface a HID device sits on, from the interface above it in the registry.
    nonisolated private static func interfaceNumber(of service: io_service_t) -> Int? {
        let value = IORegistryEntrySearchCFProperty(
            service, kIOServicePlane, "bInterfaceNumber" as CFString, kCFAllocatorDefault,
            IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents))
        return (value as? NSNumber)?.intValue
    }

    /// Whether a driver has taken the interface. A user client — the app's own, once it has the
    /// interface open — is not a driver.
    nonisolated private static func hasDriver(_ interface: io_service_t) -> Bool {
        var found = false
        forEachChild(of: interface) { child in
            if IOObjectConformsTo(child, "IOUserClient") == 0 { found = true }
        }
        return found
    }

    nonisolated private static func entryID(_ service: io_service_t) -> UInt64 {
        var entry: UInt64 = 0
        IORegistryEntryGetRegistryEntryID(service, &entry)
        return entry
    }

    nonisolated static func registryNumber(_ service: io_service_t, _ key: String) -> Int? {
        (IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? NSNumber)?.intValue
    }

    /// What the USB device above `service` and its interfaces say about themselves, from the registry.
    /// Only the USB device is asked — further up is the hub it is plugged into.
    nonisolated private static func deviceDetails(_ service: io_service_t) -> DeviceDetails? {
        var entry = service
        var owned: [io_registry_entry_t] = []
        defer { owned.forEach { IOObjectRelease($0) } }
        while IOObjectConformsTo(entry, "IOUSBHostDevice") == 0 {
            var parent: io_registry_entry_t = 0
            guard IORegistryEntryGetParentEntry(entry, kIOServicePlane, &parent) == KERN_SUCCESS else { return nil }
            owned.append(parent)
            entry = parent
        }
        let device = entry
        func string(_ key: String) -> String? {
            let value = IORegistryEntryCreateCFProperty(device, key as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? String
            return value?.isEmpty == false ? value : nil
        }
        var interfaces: [DeviceDetails.Interface] = []
        forEachChild(of: device) { child in
            guard IOObjectConformsTo(child, "IOUSBHostInterface") != 0, let number = registryNumber(child, "bInterfaceNumber")
            else { return }
            var usages: [DeviceDetails.UsagePair] = []
            forEachChild(of: child) { hid in
                guard IOObjectConformsTo(hid, "IOHIDDevice") != 0,
                      let pairs = IORegistryEntryCreateCFProperty(hid, "DeviceUsagePairs" as CFString, kCFAllocatorDefault, 0)?
                          .takeRetainedValue() as? [[String: Any]]
                else { return }
                usages += pairs.compactMap { pair in
                    guard let page = (pair["DeviceUsagePage"] as? NSNumber)?.intValue,
                          let usage = (pair["DeviceUsage"] as? NSNumber)?.intValue
                    else { return nil }
                    return DeviceDetails.UsagePair(page: page, usage: usage)
                }
            }
            interfaces.append(DeviceDetails.Interface(
                number: number, interfaceClass: registryNumber(child, "bInterfaceClass") ?? 0,
                subclass: registryNumber(child, "bInterfaceSubClass") ?? 0,
                interfaceProtocol: registryNumber(child, "bInterfaceProtocol") ?? 0, usages: usages))
        }
        return DeviceDetails(
            usbVersion: registryNumber(device, "bcdUSB") ?? 0,
            deviceRelease: registryNumber(device, "bcdDevice") ?? 0,
            speed: registryNumber(device, "UsbLinkSpeed"),
            manufacturer: string("kUSBVendorString"),
            productName: string("kUSBProductString"),
            serialNumber: string("kUSBSerialNumberString"),
            maxPower: nil,
            interfaces: interfaces.sorted { $0.number < $1.number })
    }

    nonisolated private static func forEachChild(of entry: io_registry_entry_t, _ body: (io_registry_entry_t) -> Void) {
        var children: io_iterator_t = 0
        guard IORegistryEntryGetChildIterator(entry, kIOServicePlane, &children) == KERN_SUCCESS else { return }
        defer { IOObjectRelease(children) }
        while case let child = IOIteratorNext(children), child != 0 {
            body(child)
            IOObjectRelease(child)
        }
    }

    nonisolated private static func drain(_ iterator: io_iterator_t) {
        while case let service = IOIteratorNext(iterator), service != 0 {
            IOObjectRelease(service)
        }
    }
}

/// Hands a value that is touched on one thread at a time to another.
struct UncheckedBox<Value>: @unchecked Sendable {
    let value: Value
    init(_ value: Value) { self.value = value }
}
