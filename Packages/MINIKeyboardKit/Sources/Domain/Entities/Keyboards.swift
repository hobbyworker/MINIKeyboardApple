import Foundation

/// A USB device's vendor and product IDs. These keyboards carry no name or serial number, so this is
/// all there is to tell them apart by.
public struct USBIdentity: Hashable, Sendable, Codable, CustomStringConvertible {
    public let vendorID: Int
    public let productID: Int

    public init(vendorID: Int, productID: Int) {
        self.vendorID = vendorID
        self.productID = productID
    }

    /// "1189:8890".
    public var description: String { String(format: "%04X:%04X", vendorID, productID) }
}

/// The two kinds of keyboard the app configures, told apart by USB ID. Each came with a vendor tool of
/// its own, and the two tools speak different commands.
public enum KeyboardFamily: String, Sendable, Codable, CaseIterable {
    /// 1189:8890, the keyboard of the vendor's Windows tool. Its configuration interface (USB interface
    /// 1) takes eight-byte packets and answers nothing.
    case k8890
    /// The keyboards of the vendor's cross-platform app: vendor 1189 or 514C with product 8842, 8840,
    /// 8830–8833, 8850 or 8851. Configured through 64-byte reports on interface 0; most say how many keys
    /// and knobs they have, and those read back what they hold.
    case k884x

    /// Every keyboard the app looks for, in order: the 1189:8890, then the eight product IDs the cross-platform app
    /// looks for, under vendor 1189 and then 514C.
    public static let supported: [USBIdentity] = {
        let products = [0x8842, 0x8840, 0x8830, 0x8831, 0x8832, 0x8833, 0x8850, 0x8851]
        return [USBIdentity(vendorID: 0x1189, productID: 0x8890)]
            + products.map { USBIdentity(vendorID: 0x1189, productID: $0) }
            + products.map { USBIdentity(vendorID: 0x514C, productID: $0) }
    }()

    public init?(usb: USBIdentity) {
        guard Self.supported.contains(usb) else { return nil }
        self = usb == USBIdentity(vendorID: 0x1189, productID: 0x8890) ? .k8890 : .k884x
    }

    /// The USB interface that takes the configuration.
    public var configurationInterface: Int {
        switch self {
        case .k8890: 1
        case .k884x: 0
        }
    }
}

/// How a 884x keyboard stores a key's action.
public enum RecordFormat: Hashable, Sendable {
    /// Firmware that answers identification with type 10 or above: `FD` records of three-byte entries — a delay
    /// and a code, every modifier an entry of its own. They read back.
    case standard
    /// Firmware that answers with a type below 10: `FD` records of (modifier, key) pairs and one delay for
    /// the whole key. They read back.
    case legacy
    /// A keyboard that does not answer identification: `FE` records of (modifier, key) pairs, written
    /// the way keyboards of the 1189:8840 kind are known to take them. Nothing reads back.
    case unidentified
}

/// The commands a connected keyboard takes, settled once it is connected and identified.
public enum CommandSet: Hashable, Sendable {
    /// The 1189:8890: packets after a report ID — 3, or 0 or 2 where the keyboard's descriptor says so.
    case packets(reportID: UInt8)
    /// A 884x keyboard.
    case records(RecordFormat)
}

/// What a 884x keyboard answers when asked who it is (`FB FB FB`).
public struct KeyboardIdentity: Hashable, Sendable {
    public let keyCount: Int
    public let knobCount: Int
    /// 10 or above for the standard record format, below 10 for the legacy one, as the cross-platform app's later
    /// builds tell them apart. On a keyboard of four keys and a knob it also picks between two layouts.
    public let type: Int

    public init(keyCount: Int, knobCount: Int, type: Int) {
        self.keyCount = keyCount
        self.knobCount = knobCount
        self.type = type
    }

    public var recordFormat: RecordFormat { type >= 10 ? .standard : .legacy }

    /// Whether the type is one the app knows a keyboard of: 0 and 1, which the cross-platform app picks layouts
    /// by, its standard firmware's 10, and 11 (514C:8850). Any other is handled by the same rules, untried.
    public var isKnownType: Bool { [0, 1, 10, 11].contains(type) }
}

/// What the app learned about a keyboard once it was connected.
public struct KeyboardIdentification: Hashable, Sendable {
    public let commands: CommandSet
    /// What a 884x keyboard said about itself; nil on the 8890 and on a keyboard that did not answer.
    public let identity: KeyboardIdentity?

    public init(commands: CommandSet, identity: KeyboardIdentity?) {
        self.commands = commands
        self.identity = identity
    }
}
