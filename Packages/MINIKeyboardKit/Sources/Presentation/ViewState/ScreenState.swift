import Foundation
import Domain

/// The keyboard as the main window draws it: its body and every control, turned the way it sits.
public struct KeyboardDrawing: Hashable, Sendable {
    public let frame: LayoutRect
    public let bounds: LayoutRect
    public let controls: [ControlDrawing]
}

public struct ControlDrawing: Hashable, Sendable, Identifiable {
    public enum Face: Hashable, Sendable {
        case key(Int)
        case knob(KnobAction)
    }

    public let ref: ControlRef
    public let face: Face
    public let rect: LayoutRect
    public let caption: ActionCaption
    public let isSelected: Bool
    public let isChanged: Bool
    /// The key's colour, on the LED page of a keyboard that lights each key.
    public let ledColor: RGB?

    public var id: ControlRef { ref }
}

/// A keyboard's shape drawn small, for choosing one: keys, and each knob as one body.
public struct ShapeDrawing: Hashable, Sendable {
    public struct Item: Hashable, Sendable, Identifiable {
        public let id: String
        public let rect: LayoutRect
        public let isKnob: Bool
    }

    public let frame: LayoutRect
    public let bounds: LayoutRect
    public let items: [Item]

    init(_ geometry: LayoutGeometry) {
        frame = geometry.frame
        bounds = geometry.bounds
        let keys = geometry.rects.compactMap { control, rect -> Item? in
            guard case .key(let number) = control else { return nil }
            return Item(id: "key-\(number)", rect: rect, isKnob: false)
        }
        .sorted { $0.id < $1.id }
        items = keys + geometry.knobOutlines.map { Item(id: "knob-\($0.number)", rect: $0.rect, isKnob: true) }
    }
}

/// The header's account of the keyboard.
public enum ConnectionStatus: Hashable, Sendable {
    case searching
    case needsPermission
    case openFailed(code: Int32)
    /// `keys` and `knobs` are what the keyboard said, when it said.
    case connected(usb: String, keys: Int?, knobs: Int?, isIdentified: Bool, isSimulated: Bool)
}

/// The inspector's account of the selected control.
public struct SelectionState: Hashable, Sendable {
    public let title: ControlTitle
    /// Shown when the keyboard has layers.
    public let layerNumber: Int?
    public let binding: BindingState
}

public enum BindingState: Hashable, Sendable {
    case unknown
    case nothing
    /// Each press as text, the wait for the whole key, and how many places the presses take of the limit.
    case presses(strokes: [String], keyDelay: Int, used: Int, limit: Int)
    case media(MediaChoice)
    case otherMedia(UInt16)
    case mouse(MouseChoice)
}

/// How the Keys page lays out the keys.
public enum KeyArrangement: String, CaseIterable, Hashable, Sendable {
    /// As on a full-size keyboard — the cross-platform app's page.
    case qwerty
    /// In groups, the letters in alphabetical order — the Windows tool's page.
    case alphabetical
}

/// One cap of the full-size keyboard, placed in key widths.
public struct BoardCap: Hashable, Sendable, Identifiable {
    public enum Face: Hashable, Sendable {
        case key(KeyUsage)
        /// Held for the next key, as in the modifier row of the other arrangement.
        case modifier(ModifierKey)
    }

    /// A row's width, in key widths.
    public static let rowWidth = FullKeyboard.width

    public let face: Face
    public let row: Int
    /// From the left edge.
    public let column: Double
    public let width: Double
    /// Off for a key the keyboard isn't given; it stays in its place.
    public let isEnabled: Bool

    public var id: Face { face }
}

/// A group of keys in the alphabetical arrangement, with only the keys the keyboard is given.
public struct KeyGroup: Hashable, Sendable, Identifiable {
    public enum Kind: CaseIterable, Hashable, Sendable {
        case letters, numbers, editing, symbols, functionKeys, navigation, numpad

        var keys: [KeyUsage] {
            switch self {
            case .letters: KeyUsage.letters
            case .numbers: KeyUsage.digits
            case .editing: KeyUsage.editing
            case .symbols: KeyUsage.symbols + KeyUsage.international
            case .functionKeys: KeyUsage.functionKeys + KeyUsage.extraFunctionKeys
            case .navigation: KeyUsage.system + KeyUsage.navigation
            case .numpad: KeyUsage.keypad
            }
        }
    }

    public let kind: Kind
    public let keys: [KeyUsage]

    public var id: Kind { kind }
}

/// The LED page, in the form the keyboard takes.
public enum LightingPage: Hashable, Sendable {
    /// The 1189:8890's modes.
    case modes([Int], active: Int?)
    case colorAndMode(colors: [LEDColor], modes: [Int], activeColor: LEDColor?, activeMode: Int?)
    case perKeyColor(modes: [Int], activeMode: Int?, keys: Int, selected: KeyColorSelection?)
}

public struct KeyColorSelection: Hashable, Sendable {
    public let title: ControlTitle
    public let color: RGB
}

/// The Delay page.
public enum DelayPage: Hashable, Sendable {
    case unavailable
    /// The selected key's presses, each with its wait; empty when it has none.
    case perPress(range: ClosedRange<Int>, presses: [PressDelay])
    /// The selected key's one wait; nil when no key is selected.
    case perKey(range: ClosedRange<Int>, value: Int?)
}

public struct PressDelay: Hashable, Sendable, Identifiable {
    public let index: Int
    public let text: String
    public let delay: Int

    public var id: Int { index }
}

/// The layout sheet.
public struct LayoutSheetState: Hashable, Sendable {
    public enum Mode: Hashable, Sendable {
        /// The keyboard said its shape: it only turns.
        case fixed
        /// One of the cross-platform app's layouts.
        case catalog([LayoutChoice], selectedID: String)
        /// Keys, keys to a row and knobs, within the limits.
        case arrangement(keys: Int, columns: Int, knobs: Int, maxKeys: Int, maxKnobs: Int)
    }

    public let usb: String
    /// What the keyboard said of its keys and knobs, when it said.
    public let reportedKeys: Int?
    public let reportedKnobs: Int?
    public let mode: Mode
    /// Quarter turns clockwise, 0–3.
    public let quarterTurns: Int
    /// The first time: no Cancel.
    public let isRequired: Bool
}

public struct LayoutChoice: Hashable, Sendable, Identifiable {
    public let id: String
    public let keys: Int
    public let knobs: Int
    public let drawing: ShapeDrawing
}

/// What is known about the keyboard plugged in — from its USB descriptors and, on keyboards that answer, from
/// the answer. Nothing is guessed: what the keyboard doesn't say is nil.
public struct KeyboardInfo: Hashable, Sendable {
    public enum Firmware: Hashable, Sendable {
        /// What a 884x keyboard answered: the type, keys and knobs.
        case reported(type: Int, keys: Int, knobs: Int)
        /// `bcdDevice`, "1.02".
        case release(String)
        case unknown
    }

    public struct Interface: Hashable, Sendable, Identifiable {
        public let number: Int
        public let roles: [InterfaceRole]
        /// The interface the app writes to.
        public let isConfiguration: Bool

        public var id: Int { number }
    }

    /// The interface the app writes to, and how.
    public struct Channel: Hashable, Sendable {
        public enum Path: Hashable, Sendable {
            /// Straight to the interface's interrupt OUT endpoint.
            case usb(outEndpoint: UInt8)
            /// Through the HID device macOS made of the interface.
            case hid
            case simulated
        }

        public let interface: Int
        public let path: Path
        public let reportID: Int
        /// Bytes, the report ID included.
        public let reportLength: Int
    }

    /// The commands the keyboard takes.
    public enum Commands: Hashable, Sendable {
        /// The 1189:8890's packets.
        case packets(reportID: Int)
        /// A 884x keyboard's records: on the standard firmware, the legacy one, or one that doesn't answer.
        case standard, legacy, unidentified
        /// Not known yet.
        case unknown
    }

    public let usbID: String
    public let name: String?
    public let manufacturer: String?
    public let serialNumber: String?
    public let firmware: Firmware
    /// "USB 1.1 · 12 Mb/s".
    public let usb: String?
    /// mA.
    public let power: Int?
    public let interfaces: [Interface]
    public let channel: Channel
    public let commands: Commands

    public init(keyboard: ConnectedKeyboard, identification: KeyboardIdentification?) {
        let details = keyboard.details
        usbID = keyboard.usb.description
        name = details?.productName
        manufacturer = details?.manufacturer
        serialNumber = details?.serialNumber
        if let identity = identification?.identity {
            firmware = .reported(type: identity.type, keys: identity.keyCount, knobs: identity.knobCount)
        } else if let release = details?.deviceRelease, release != 0 {
            firmware = .release(String(format: "%X.%02X", release >> 8, release & 0xFF))
        } else {
            firmware = .unknown
        }
        usb = details.map(Self.usbText)
        power = details?.maxPower
        interfaces = (details?.interfaces ?? []).map { interface in
            Interface(number: interface.number, roles: Self.roles(of: interface, configuration: keyboard.interfaceNumber),
                      isConfiguration: interface.number == keyboard.interfaceNumber)
        }
        let path: Channel.Path = switch keyboard.channel {
        case .usb(let endpoint): .usb(outEndpoint: endpoint)
        case .hid: .hid
        case .simulated: .simulated
        }
        channel = Channel(interface: keyboard.interfaceNumber, path: path, reportID: Int(keyboard.reportID),
                          reportLength: keyboard.reportLength)
        commands = switch identification?.commands {
        case .packets(let reportID)?: .packets(reportID: Int(reportID))
        case .records(.standard)?: .standard
        case .records(.legacy)?: .legacy
        case .records(.unidentified)?: .unidentified
        case nil: .unknown
        }
    }

    /// What an interface is for, by the usages of the HID device macOS made of it, or by its descriptor when
    /// no driver took it.
    static func roles(of interface: DeviceDetails.Interface, configuration: Int) -> [InterfaceRole] {
        var roles: [InterfaceRole] = []
        for pair in interface.usages {
            let role: InterfaceRole = switch (pair.page, pair.usage) {
            case (0x01, 0x06): .keyboard
            case (0x01, 0x01), (0x01, 0x02): .mouse
            case (0x0C, _): .media
            case (0xFF00..., _): .configuration
            default: .other
            }
            if !roles.contains(role) { roles.append(role) }
        }
        if roles.isEmpty, interface.number == configuration { roles = [.configuration] }
        if roles.isEmpty {
            roles = switch (interface.interfaceClass, interface.subclass, interface.interfaceProtocol) {
            case (3, 1, 1): [.keyboard]
            case (3, 1, 2): [.mouse]
            default: [.other]
            }
        }
        return roles
    }

    static func usbText(_ details: DeviceDetails) -> String {
        let version = details.usbVersion
        let major = (version >> 8) & 0xFF, minor = (version >> 4) & 0x0F, sub = version & 0x0F
        var text = "USB \(major).\(minor)" + (sub == 0 ? "" : ".\(sub)")
        if let speed = details.speed {
            text += speed >= 1_000_000_000 ? " · \(speed / 1_000_000_000) Gb/s"
                : speed >= 1_000_000 ? " · \(speed / 1_000_000) Mb/s" : " · \(speed / 1000) kb/s"
        }
        return text
    }
}

public enum InterfaceRole: Hashable, Sendable {
    case keyboard, mouse, media, configuration, other
}

/// One of the keyboards plugged in, to choose which the app opens.
public struct KeyboardChoice: Hashable, Sendable, Identifiable {
    public let id: String
    /// Its USB ID — "1189:8890" — numbered by port when more than one with that ID is plugged in: "1189:8890 (2)".
    public let title: String
    public let isSelected: Bool
}

/// A keyboard the simulator can play.
public struct SimulatorChoice: Hashable, Sendable, Identifiable {
    public enum Group: CaseIterable, Hashable, Sendable {
        case k8890, standard, legacy, unidentified
    }

    /// What the simulated keyboard is; the menu names it.
    public enum Kind: Hashable, Sendable {
        case k8890(reportID: Int)
        /// It answers with these, on this USB ID.
        case identified(keys: Int, knobs: Int, type: Int, usb: String)
        /// It doesn't answer.
        case unidentified(usb: String)
    }

    public let id: String
    public let group: Group
    public let kind: Kind
    let model: SimulatedModel

    /// Whether everyone's menu has it, not only a debug build's: the 8890 as it ships (report ID 3), each 884x
    /// layout on its standard records, and a 884x that doesn't answer. The 8890's other report IDs and the legacy
    /// records are for testing the app.
    public var isForEveryone: Bool {
        switch group {
        case .k8890: kind == .k8890(reportID: 3)
        case .legacy: false
        case .standard, .unidentified: true
        }
    }

    init(_ model: SimulatedModel) {
        self.model = model
        id = model.id
        switch model.kind {
        case .k8890(let reportID):
            group = .k8890
            kind = .k8890(reportID: Int(reportID))
        case .identified(let identity):
            group = identity.recordFormat == .standard ? .standard : .legacy
            kind = .identified(keys: identity.keyCount, knobs: identity.knobCount, type: identity.type, usb: model.usb.description)
        case .unidentified:
            group = .unidentified
            kind = .unidentified(usb: model.usb.description)
        }
    }
}
