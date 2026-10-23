import Foundation
import IOKit
import IOKit.hid
import Domain

/// A 884x keyboard's interface 0, opened as a HID device: requests go out as output reports, answers come
/// in as input reports. The interface is also the keyboard's keyboard, so macOS opens it only for an app
/// allowed Input Monitoring.
@MainActor
final class HIDDeviceChannel: ReportChannel {
    let framing = ReportFraming(reportID: K884xCommands.reportID, length: K884xCommands.reportLength)
    private let device: IOHIDDevice
    private let writer: HIDWriter
    private let replies = ReplyQueue()
    private let buffer: UnsafeMutablePointer<UInt8>
    private let bufferSize: Int
    private let received: (([UInt8]) -> Void)?
    private var isOpen = true

    /// Answers are 64-byte reports; shorter ones are the keyboard's typing, media keys or mouse.
    static let minimumReplyLength = 32

    /// Opens the device and listens for its input reports on the main run loop. `received` sees every
    /// answer, for the log.
    static func open(_ device: IOHIDDevice, received: (([UInt8]) -> Void)? = nil) throws(OpenFailure) -> HIDDeviceChannel {
        let status = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        guard status == kIOReturnSuccess else { throw OpenFailure(status: status) }
        return HIDDeviceChannel(device: device, received: received)
    }

    struct OpenFailure: Error {
        let status: IOReturn
    }

    private init(device: IOHIDDevice, received: (([UInt8]) -> Void)?) {
        self.device = device
        self.received = received
        writer = HIDWriter(device: device)
        let reported = (IOHIDDeviceGetProperty(device, kIOHIDMaxInputReportSizeKey as CFString) as? NSNumber)?.intValue ?? 0
        bufferSize = max(reported, K884xCommands.reportLength)
        buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        buffer.initialize(repeating: 0, count: bufferSize)
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(device, buffer, bufferSize, { context, _, _, _, reportID, report, length in
            guard let context else { return }
            var bytes = Array(UnsafeBufferPointer(start: report, count: length))
            // Answers are kept report ID first, as the vendor app reads them.
            if reportID != 0, bytes.first != UInt8(truncatingIfNeeded: reportID) {
                bytes.insert(UInt8(truncatingIfNeeded: reportID), at: 0)
            }
            let channel = Unmanaged<HIDDeviceChannel>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { channel.receive(bytes) }
        }, context)
        IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
    }

    private func receive(_ report: [UInt8]) {
        guard isOpen, report.count >= Self.minimumReplyLength else { return }
        received?(report)
        replies.receive(report)
    }

    func write(_ report: [UInt8]) async throws(KeyboardDeviceError) {
        guard isOpen else { throw .notConnected }
        let status = await writer.write(report)
        guard status == kIOReturnSuccess else { throw .writeFailed(code: status) }
    }

    func discardPendingReplies() {
        replies.discard()
    }

    func nextReply(timeout: Duration) async -> [UInt8]? {
        guard isOpen else { return nil }
        return await replies.next(timeout: timeout)
    }

    func close() {
        guard isOpen else { return }
        isOpen = false
        IOHIDDeviceRegisterInputReportCallback(device, buffer, bufferSize, nil, nil)
        IOHIDDeviceUnscheduleFromRunLoop(device, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        // Reports are delivered on the main run loop, so none is being handled while the buffer goes.
        buffer.deallocate()
        replies.finish(with: nil)
        writer.close()
    }
}

/// `IOHIDDeviceSetReport` blocks, so reports are written on a queue of their own, one at a time.
final class HIDWriter: @unchecked Sendable {
    private let device: IOHIDDevice
    private let queue = DispatchQueue(label: "MINIKeyboard.HIDWriter")

    init(device: IOHIDDevice) {
        self.device = device
    }

    /// A numbered report keeps its ID as the first byte, as hidapi does on macOS.
    func write(_ report: [UInt8]) async -> IOReturn {
        await withCheckedContinuation { continuation in
            queue.async {
                let status = report.withUnsafeBufferPointer { bytes in
                    IOHIDDeviceSetReport(self.device, kIOHIDReportTypeOutput, CFIndex(report.first ?? 0),
                                         bytes.baseAddress!, bytes.count)
                }
                continuation.resume(returning: status)
            }
        }
    }

    func close() {
        queue.async { IOHIDDeviceClose(self.device, IOOptionBits(kIOHIDOptionsTypeNone)) }
    }
}
