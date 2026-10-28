import Foundation

/// The layout a user chose for a keyboard that doesn't say its shape, and how the keyboard is turned.
public struct LayoutProfile: Hashable, Sendable, Codable {
    public var layoutID: String
    public var rotation: Rotation

    public init(layoutID: String, rotation: Rotation) {
        self.layoutID = layoutID
        self.rotation = rotation
    }
}

/// The layout the app draws for the connected keyboard, and where it came from.
public struct ResolvedLayout: Hashable, Sendable {
    public enum Source: Hashable, Sendable {
        /// The keyboard said how many keys and knobs it has.
        case identified
        /// The user chose it.
        case chosen
        /// Nobody has chosen one yet: what the keyboard's vendor tool draws for a keyboard it knows nothing of.
        case assumed
    }

    public let layout: KeyboardLayout
    public let rotation: Rotation
    public let source: Source
    /// The cross-platform app's layouts the user may choose from; empty when the keyboard said its shape, or
    /// is arranged instead.
    public let choices: [KeyboardLayout]
    /// For a keyboard no vendor tool draws: how large an arrangement (`GridShape`) the user may give it.
    public let grid: GridLimits?

    public init(layout: KeyboardLayout, rotation: Rotation, source: Source, choices: [KeyboardLayout], grid: GridLimits? = nil) {
        self.layout = layout
        self.rotation = rotation
        self.source = source
        self.choices = choices
        self.grid = grid
    }

    public var needsChoice: Bool { source == .assumed }
}

/// One line of the device log: a report written or read — every byte of it — or something that happened.
public struct DeviceLogEntry: Identifiable, Hashable, Sendable {
    public enum Content: Hashable, Sendable {
        /// A report written to the keyboard, its report ID first unless it is 0.
        case output([UInt8])
        /// A report the keyboard sent.
        case input([UInt8])
        case event(DeviceLogEvent)
    }

    public let id: UUID
    public let date: Date
    public let content: Content

    public init(_ content: Content, date: Date = Date(), id: UUID = UUID()) {
        self.id = id
        self.date = date
        self.content = content
    }
}

/// What happened to the connection, for the device log.
public enum DeviceLogEvent: Hashable, Sendable {
    case searching
    case connected(USBIdentity, interface: Int)
    case needsPermission
    case openFailed(code: Int32)
    case writeFailed(code: Int32)
    /// A simulated keyboard took the place of the one on USB.
    case simulated(modelID: String)
}

/// Which keyboard the app talks to: the one on USB, or one that exists only in the app.
public enum KeyboardSource: Hashable, Sendable {
    case hardware
    case simulated(SimulatedModel)

    public var isSimulated: Bool {
        if case .simulated = self { return true }
        return false
    }
}

/// A keyboard the simulator plays: its USB ID, the commands it takes and, for a 884x keyboard that
/// answers, what it says about itself.
public struct SimulatedModel: Hashable, Sendable, Identifiable {
    public enum Kind: Hashable, Sendable {
        /// A 1189:8890 whose descriptor declares this report ID.
        case k8890(reportID: UInt8)
        /// A 884x keyboard that answers identification.
        case identified(KeyboardIdentity)
        /// A 884x keyboard that doesn't.
        case unidentified
    }

    public let usb: USBIdentity
    public let kind: Kind

    public init(usb: USBIdentity, kind: Kind) {
        self.usb = usb
        self.kind = kind
    }

    public var id: String {
        switch kind {
        case .k8890(let reportID): "8890-\(reportID)"
        case .identified(let identity): "\(usb)-\(identity.keyCount)-\(identity.knobCount)-\(identity.type)"
        case .unidentified: "\(usb)-unidentified"
        }
    }

    public var family: KeyboardFamily { KeyboardFamily(usb: usb) ?? .k884x }

    /// The 8890 on each report ID, then every layout a 884x keyboard can be identified as on each format,
    /// then a 884x keyboard that doesn't answer.
    public static let all: [SimulatedModel] = {
        let k8890 = USBIdentity(vendorID: 0x1189, productID: 0x8890)
        var models = [3, 0, 2].map { SimulatedModel(usb: k8890, kind: .k8890(reportID: UInt8($0))) }
        for format in [RecordFormat.standard, .legacy] {
            for layout in KeyboardLayout.all {
                if let model = identified(as: layout, format: format) { models.append(model) }
            }
        }
        models.append(SimulatedModel(usb: USBIdentity(vendorID: 0x1189, productID: 0x8840), kind: .unidentified))
        return models
    }()

    /// A keyboard that says what makes the cross-platform app draw `layout` with `format`: type 10 for
    /// the standard format, 0 or 1 for the legacy one, with a product ID the rule looks at. Nil when no
    /// answer leads there — 4add1 and 4add2 exist only on the legacy format.
    public static func identified(as layout: KeyboardLayout, format: RecordFormat) -> SimulatedModel? {
        let candidates: [(type: Int, productID: Int)] = format == .standard
            ? [(10, 0x8840), (10, 0x8850), (10, 0x8851)]
            : [(0, 0x8840), (0, 0x8850), (0, 0x8851), (1, 0x8840)]
        for candidate in candidates {
            let identity = KeyboardIdentity(keyCount: layout.keyCount, knobCount: layout.knobCount, type: candidate.type)
            guard KeyboardLayout.identifiedID(for: identity, productID: candidate.productID) == layout.id else { continue }
            // 8851 under 514C, so the simulator plays that vendor too.
            let vendor = candidate.productID == 0x8851 ? 0x514C : 0x1189
            return SimulatedModel(usb: USBIdentity(vendorID: vendor, productID: candidate.productID), kind: .identified(identity))
        }
        return nil
    }
}
