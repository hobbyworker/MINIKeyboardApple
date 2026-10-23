/// One action of a knob. Some knobs also turn while pressed.
public enum KnobPart: Int, CaseIterable, Hashable, Sendable, Comparable {
    case rotateLeft, press, rotateRight, pressRotateLeft, pressRotateRight

    public static func < (lhs: KnobPart, rhs: KnobPart) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// A key, or one action of a knob — what the user selects and binds.
public enum ControlID: Hashable, Sendable, Comparable {
    case key(number: Int)
    case knob(number: Int, part: KnobPart)

    public var isKey: Bool {
        if case .key = self { return true }
        return false
    }

    public var knobNumber: Int? {
        if case .knob(let number, _) = self { return number }
        return nil
    }

    public static func < (lhs: ControlID, rhs: ControlID) -> Bool {
        switch (lhs, rhs) {
        case let (.key(a), .key(b)): a < b
        case (.key, .knob): true
        case (.knob, .key): false
        case let (.knob(a, p), .knob(b, q)): (a, p.rawValue) < (b, q.rawValue)
        }
    }
}

/// How far a keyboard is turned clockwise from the way its layout is drawn — kept with the user's choice.
public enum Rotation: Int, CaseIterable, Hashable, Sendable, Codable {
    case upright, quarter, half, threeQuarters

    public var next: Rotation { Rotation(rawValue: (rawValue + 1) % 4) ?? .upright }
}

/// A keyboard's controls, named as the cross-platform app names its layouts ("6add1" — six keys and a knob),
/// or as an arrangement the user set (`GridShape`). Where they are drawn is the presentation's business,
/// where they are stored the device's.
public struct KeyboardLayout: Hashable, Sendable, Identifiable {
    public let id: String
    public let controls: [ControlID]

    public init(id: String, controls: [ControlID]) {
        self.id = id
        self.controls = controls
    }

    public var keyCount: Int { controls.filter(\.isKey).count }

    public var knobCount: Int { Set(controls.compactMap(\.knobNumber)).count }

    /// What the cross-platform app draws when a keyboard's answer matches no layout.
    public static let fallbackID = "15add3"

    public static func named(_ id: String) -> KeyboardLayout? {
        all.first { $0.id == id }
    }

    /// The layout the cross-platform app draws for what a keyboard says of itself
    /// (`Widget::Identify_KeyBoard_style`). `type` also tells two keyboards of four keys and a knob apart;
    /// `productID` tells two others apart.
    public static func identifiedID(for identity: KeyboardIdentity, productID: Int) -> String {
        switch (identity.keyCount, identity.knobCount) {
        case (0, 1): "0add1"
        case (0, 2): productID == 0x8850 ? "0add2" : "0add1"
        case (0, 3): "0add3"
        case (1, 0): "1add0"
        case (2, 0): "2add0"
        case (3, 0): "3add0"
        case (3, 1): "3add1"
        case (4, 0): "4Key"
        case (4, 1) where identity.type == 0: productID == 0x8851 ? "4add2" : "4add1"
        case (4, 1) where identity.type == 1: "4add2"
        case (4, 3): "4add3"
        case (5, 0): "5Key_Mute"
        case (6, 0): "6Key"
        case (6, 1): "6add1"
        case (6, 2): "6add2"
        case (9, 2): "9add2"
        case (9, 3): "9add3"
        case (11, 3): "11add3"
        case (12, 0): "12add0"
        case (12, 2): "12add2"
        case (12, 3): "12add3"
        case (12, 4): "12add4"
        case (16, 0): "16add0"
        case (16, 3): "16add3"
        case (21, 1): "21add1"
        default: fallbackID
        }
    }
}
