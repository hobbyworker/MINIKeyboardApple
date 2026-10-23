/// The modifier keys of a key press, as the bits of a HID keyboard report (usages 0xE0–0xE7). The
/// vendor tools call Option "Alt" and Command "Win".
public struct Modifiers: OptionSet, Hashable, Sendable, Codable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let control = Modifiers(rawValue: 0x01)
    public static let shift = Modifiers(rawValue: 0x02)
    public static let option = Modifiers(rawValue: 0x04)
    public static let command = Modifiers(rawValue: 0x08)
    public static let rightControl = Modifiers(rawValue: 0x10)
    public static let rightShift = Modifiers(rawValue: 0x20)
    public static let rightOption = Modifiers(rawValue: 0x40)
    public static let rightCommand = Modifiers(rawValue: 0x80)

    /// Each modifier on its own, lowest bit first.
    public static let each: [Modifiers] = (0..<8).map { Modifiers(rawValue: 1 << $0) }

    /// The modifiers set here, lowest bit first.
    public var members: [Modifiers] { Self.each.filter(contains) }

    public var count: Int { rawValue.nonzeroBitCount }
}

/// One press: modifiers held while a key goes down. A key of 0 holds the modifiers alone, which turns
/// the keyboard key into a modifier key — so such a press is only ever a key's whole action.
public struct KeyStroke: Hashable, Sendable {
    public var modifiers: Modifiers
    /// The key's usage on the HID keyboard page (`KeyUsage`), or 0 for none.
    public var key: UInt8
    /// Milliseconds to wait before this press. Only standard-format keyboards keep it.
    public var delay: Int

    public init(modifiers: Modifiers = [], key: UInt8, delay: Int = 0) {
        self.modifiers = modifiers
        self.key = key
        self.delay = delay
    }

    public var isModifiersOnly: Bool { key == 0 }
}

/// Key presses one keyboard key sends, in order.
public struct KeyMacro: Hashable, Sendable {
    public var strokes: [KeyStroke]
    /// Milliseconds to wait, for the whole key. Only legacy-format keyboards keep it.
    public var delay: Int

    public init(_ strokes: [KeyStroke] = [], delay: Int = 0) {
        self.strokes = strokes
        self.delay = delay
    }

    /// One modifiers-only press, or nothing at all, but never one among others.
    public var isWellFormed: Bool {
        strokes.count <= 1 || !strokes.contains(where: \.isModifiersOnly)
    }
}

/// What a keyboard key or knob action does.
public enum KeyAction: Hashable, Sendable {
    /// Nothing: the key is cleared.
    case unassigned
    case keys(KeyMacro)
    case media(MediaKey)
    case mouse(MouseAction)
}

/// A key on the HID consumer page — media and application keys.
public struct MediaKey: Hashable, Sendable, Identifiable {
    /// The consumer-page usage.
    public let usage: UInt16

    public init(usage: UInt16) {
        self.usage = usage
    }

    public var id: UInt16 { usage }

    public static let playPause = MediaKey(usage: 0xCD)
    public static let stop = MediaKey(usage: 0xB7)
    public static let previousTrack = MediaKey(usage: 0xB6)
    public static let nextTrack = MediaKey(usage: 0xB5)
    public static let mute = MediaKey(usage: 0xE2)
    public static let volumeUp = MediaKey(usage: 0xE9)
    public static let volumeDown = MediaKey(usage: 0xEA)
    public static let brightnessUp = MediaKey(usage: 0x6F)
    public static let brightnessDown = MediaKey(usage: 0x70)
    public static let bassUp = MediaKey(usage: 0x152)
    public static let bassDown = MediaKey(usage: 0x153)
    public static let trebleUp = MediaKey(usage: 0x154)
    public static let trebleDown = MediaKey(usage: 0x155)
    public static let mediaPlayer = MediaKey(usage: 0x183)
    public static let email = MediaKey(usage: 0x18A)
    public static let calculator = MediaKey(usage: 0x192)
    public static let myComputer = MediaKey(usage: 0x194)
    public static let webHome = MediaKey(usage: 0x223)
    public static let webBack = MediaKey(usage: 0x224)
    public static let webForward = MediaKey(usage: 0x225)
    public static let webRefresh = MediaKey(usage: 0x227)

    /// The cross-platform app's media buttons, in its order.
    public static let all: [MediaKey] = [
        .playPause, .stop, .previousTrack, .nextTrack, .myComputer, .brightnessUp, .brightnessDown,
        .mediaPlayer, .mute, .volumeUp, .volumeDown, .calculator, .webHome, .email, .bassUp, .bassDown,
        .trebleUp, .trebleDown, .webRefresh, .webForward, .webBack,
    ]

    /// The Windows tool's six.
    public static let basic: [MediaKey] = [.playPause, .previousTrack, .nextTrack, .mute, .volumeUp, .volumeDown]
}

/// The mouse buttons and wheel moves both vendor tools offer.
public enum MouseAction: Int, CaseIterable, Hashable, Sendable {
    case leftClick, middleClick, rightClick
    case wheelUp, wheelDown
    case controlWheelUp, controlWheelDown
    case shiftWheelUp, shiftWheelDown
    case optionWheelUp, optionWheelDown

    /// HID mouse button bits.
    public var buttons: UInt8 {
        switch self {
        case .leftClick: 0x01
        case .rightClick: 0x02
        case .middleClick: 0x04
        default: 0
        }
    }

    /// One notch up (0x01) or down (0xFF), or 0.
    public var wheel: UInt8 {
        switch self {
        case .wheelUp, .controlWheelUp, .shiftWheelUp, .optionWheelUp: 0x01
        case .wheelDown, .controlWheelDown, .shiftWheelDown, .optionWheelDown: 0xFF
        default: 0
        }
    }

    /// The modifier held while the wheel turns.
    public var modifiers: Modifiers {
        switch self {
        case .controlWheelUp, .controlWheelDown: .control
        case .shiftWheelUp, .shiftWheelDown: .shift
        case .optionWheelUp, .optionWheelDown: .option
        default: []
        }
    }

    /// The action with these buttons, or this wheel move and modifier; nil when there is none.
    public init?(buttons: UInt8, wheel: UInt8, modifiers: Modifiers) {
        let match: MouseAction?
        if buttons != 0 {
            match = Self.allCases.first { $0.buttons == buttons }
        } else if wheel != 0 {
            match = Self.allCases.first { $0.buttons == 0 && $0.wheel == wheel && $0.modifiers == modifiers }
        } else {
            match = nil
        }
        guard let match else { return nil }
        self = match
    }
}
