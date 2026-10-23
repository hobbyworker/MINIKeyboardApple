/// A colour with one byte per channel.
public struct KeyColor: Hashable, Sendable {
    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }
}

/// The colours a legacy-format or unidentified 884x keyboard lights in, as the high nibble it takes.
public enum LightColor: UInt8, CaseIterable, Hashable, Sendable {
    case red = 1, orange, yellow, green, cyan, blue, purple
}

/// What one layer's lights do, in the form the keyboard takes.
public enum LayerLighting: Hashable, Sendable {
    /// The 1189:8890: one of its modes (`LightingSupport.modes`).
    case mode(UInt8)
    /// A legacy-format or unidentified 884x keyboard: a colour and a mode, 0–5.
    case colorMode(color: LightColor, mode: UInt8)
    /// A standard-format keyboard: a mode, 0–5, and a colour for each of keys 1–16.
    case perKey(mode: UInt8, colors: [KeyColor])

    public var mode: UInt8 {
        switch self {
        case .mode(let mode), .colorMode(_, let mode), .perKey(let mode, _): mode
        }
    }
}

/// What a keyboard can do with its lights.
public enum LightingSupport: Hashable, Sendable {
    /// The 1189:8890's three modes, one per layer.
    case modes([UInt8])
    /// A colour and a mode per layer.
    case colorAndMode(modes: ClosedRange<UInt8>)
    /// A mode per layer and a colour for each of the first keys.
    case perKeyColor(modes: ClosedRange<UInt8>, keys: Int)

    /// The 1189:8890's modes 0–2, named for what they do on a 1189:8890 with six keys and a knob.
    public static let k8890Modes: [UInt8] = [0, 1, 2]
    /// Keys whose colour the standard format stores.
    public static let colorKeyCount = 16
}
