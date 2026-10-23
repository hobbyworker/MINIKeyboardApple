/// A keyboard whose configuration interface the app has open.
public struct ConnectedKeyboard: Hashable, Sendable {
    public enum Channel: Hashable, Sendable {
        /// Written over USB directly — an interface no driver takes (the 1189:8890's).
        case usb(outEndpoint: UInt8)
        /// Written and read as a HID device.
        case hid
        /// A keyboard that exists only in the app (debug builds).
        case simulated
    }

    public let usb: USBIdentity
    public let family: KeyboardFamily
    public let interfaceNumber: Int
    public let channel: Channel
    /// The report ID the configuration goes after, from the interface's report descriptor.
    public let reportID: UInt8
    /// Bytes per output report, the report ID included.
    public let reportLength: Int
    /// What the USB device says about itself; nil for a simulated keyboard.
    public let details: DeviceDetails?

    public init(
        usb: USBIdentity, family: KeyboardFamily, interfaceNumber: Int, channel: Channel, reportID: UInt8,
        reportLength: Int, details: DeviceDetails?
    ) {
        self.usb = usb
        self.family = family
        self.interfaceNumber = interfaceNumber
        self.channel = channel
        self.reportID = reportID
        self.reportLength = reportLength
        self.details = details
    }
}

public enum ConnectionState: Hashable, Sendable {
    case searching
    case connected(ConnectedKeyboard)
    /// macOS opens the keyboard only once Input Monitoring is allowed for the app.
    case needsPermission
    /// Opening failed for another reason (an IOReturn code).
    case openFailed(code: Int32)

    public var keyboard: ConnectedKeyboard? {
        if case .connected(let keyboard) = self { return keyboard }
        return nil
    }
}

/// Why a transfer with the keyboard failed.
public enum KeyboardDeviceError: Error, Hashable, Sendable {
    /// No keyboard is open.
    case notConnected
    /// A report could not be written (an IOReturn code).
    case writeFailed(code: Int32)
    /// An answer did not come in time.
    case noReply
    /// An answer was too short to read.
    case invalidReply
    /// The keyboard has no command for this.
    case unsupported
}

/// What the USB device and its interfaces say about themselves — read from what macOS already knows,
/// never asked of the keyboard. These keyboards carry no strings and their vendor IDs aren't the maker's,
/// so nothing here is guessed at.
public struct DeviceDetails: Hashable, Sendable {
    /// `bcdUSB`, e.g. 0x0110.
    public var usbVersion: Int
    /// `bcdDevice`; 0 on keyboards that don't say.
    public var deviceRelease: Int
    /// Link speed in bits per second.
    public var speed: Int?
    public var manufacturer: String?
    public var productName: String?
    public var serialNumber: String?
    /// The most current the keyboard asks for, in mA (`bMaxPower`), when the configuration descriptor was
    /// read.
    public var maxPower: Int?
    public var interfaces: [Interface]

    public init(
        usbVersion: Int, deviceRelease: Int, speed: Int?, manufacturer: String?, productName: String?,
        serialNumber: String?, maxPower: Int?, interfaces: [Interface]
    ) {
        self.usbVersion = usbVersion
        self.deviceRelease = deviceRelease
        self.speed = speed
        self.manufacturer = manufacturer
        self.productName = productName
        self.serialNumber = serialNumber
        self.maxPower = maxPower
        self.interfaces = interfaces
    }

    public struct Interface: Hashable, Sendable, Identifiable {
        public var number: Int
        public var interfaceClass: Int
        public var subclass: Int
        public var interfaceProtocol: Int
        /// The (usage page, usage) pairs of the HID device macOS made of it; empty when no driver took it.
        public var usages: [UsagePair]

        public init(number: Int, interfaceClass: Int, subclass: Int, interfaceProtocol: Int, usages: [UsagePair]) {
            self.number = number
            self.interfaceClass = interfaceClass
            self.subclass = subclass
            self.interfaceProtocol = interfaceProtocol
            self.usages = usages
        }

        public var id: Int { number }
    }

    public struct UsagePair: Hashable, Sendable {
        public var page: Int
        public var usage: Int

        public init(page: Int, usage: Int) {
            self.page = page
            self.usage = usage
        }
    }
}
