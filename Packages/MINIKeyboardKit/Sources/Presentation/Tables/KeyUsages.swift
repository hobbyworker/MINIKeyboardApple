import Domain

/// A key on the HID keyboard page and how to show it. Labels are the same in every language — letters,
/// digits and the symbols macOS prints on its keys; the app names the keys in the user's language.
public struct KeyUsage: Hashable, Sendable, Identifiable {
    public let usage: UInt8
    /// What a key cap shows: "A", "F5", "⌫".
    public let label: String
    /// The shifted character a key cap shows above, if any.
    public let shifted: String?

    public var id: UInt8 { usage }

    init(_ usage: UInt8, _ label: String, shifted: String? = nil) {
        self.usage = usage
        self.label = label
        self.shifted = shifted
    }
}

extension KeyUsage {
    /// Every key both vendor tools offer, and F13–F24 and the two non-US keys the cross-platform app adds.
    public static let all: [KeyUsage] = letters + digits + editing + symbols + functionKeys + system + navigation
        + keypad + extraFunctionKeys + international

    public static func named(_ usage: UInt8) -> KeyUsage? {
        byUsage[usage]
    }

    private static let byUsage = Dictionary(uniqueKeysWithValues: all.map { ($0.usage, $0) })

    public static let letters: [KeyUsage] = (0..<26).map { index in
        let letter = String(UnicodeScalar(UInt8(ascii: "A") + UInt8(index)))
        return KeyUsage(0x04 + UInt8(index), letter)
    }

    public static let digits: [KeyUsage] = zip(Array("1234567890"), Array("!@#$%^&*()")).enumerated().map { index, pair in
        KeyUsage(0x1E + UInt8(index), String(pair.0), shifted: String(pair.1))
    }

    public static let editing: [KeyUsage] = [
        KeyUsage(0x28, "↩"),
        KeyUsage(0x29, "esc"),
        KeyUsage(0x2A, "⌫"),
        KeyUsage(0x2B, "⇥"),
        KeyUsage(0x2C, "Space"),
        KeyUsage(0x39, "⇪"),
        KeyUsage(0x65, "▤"),
    ]

    public static let symbols: [KeyUsage] = [
        KeyUsage(0x2D, "-", shifted: "_"),
        KeyUsage(0x2E, "=", shifted: "+"),
        KeyUsage(0x2F, "[", shifted: "{"),
        KeyUsage(0x30, "]", shifted: "}"),
        KeyUsage(0x31, "\\", shifted: "|"),
        KeyUsage(0x33, ";", shifted: ":"),
        KeyUsage(0x34, "'", shifted: "\""),
        KeyUsage(0x35, "`", shifted: "~"),
        KeyUsage(0x36, ",", shifted: "<"),
        KeyUsage(0x37, ".", shifted: ">"),
        KeyUsage(0x38, "/", shifted: "?"),
    ]

    public static let functionKeys: [KeyUsage] = (1...12).map { KeyUsage(0x39 + UInt8($0), "F\($0)") }

    public static let extraFunctionKeys: [KeyUsage] = (13...24).map { KeyUsage(0x5B + UInt8($0), "F\($0)") }

    public static let system: [KeyUsage] = [
        KeyUsage(0x46, "PrtSc"),
        KeyUsage(0x47, "ScrLk"),
        KeyUsage(0x48, "Pause"),
    ]

    public static let navigation: [KeyUsage] = [
        KeyUsage(0x49, "Ins"),
        KeyUsage(0x4A, "↖"),
        KeyUsage(0x4B, "⇞"),
        KeyUsage(0x4C, "⌦"),
        KeyUsage(0x4D, "↘"),
        KeyUsage(0x4E, "⇟"),
        KeyUsage(0x4F, "→"),
        KeyUsage(0x50, "←"),
        KeyUsage(0x51, "↓"),
        KeyUsage(0x52, "↑"),
    ]

    public static let keypad: [KeyUsage] = [
        KeyUsage(0x53, "Num"),
        KeyUsage(0x54, "÷"),
        KeyUsage(0x55, "×"),
        KeyUsage(0x56, "−"),
        KeyUsage(0x57, "+"),
        KeyUsage(0x58, "⌤"),
    ] + (1...9).map { KeyUsage(0x58 + UInt8($0), "\($0)") } + [
        KeyUsage(0x62, "0"),
        KeyUsage(0x63, "."),
    ]

    /// The two keys ISO keyboards have and ANSI ones don't ("Non-US # and ~", "Non-US \ and |").
    public static let international: [KeyUsage] = [
        KeyUsage(0x32, "#", shifted: "~"),
        KeyUsage(0x64, "\\", shifted: "|"),
    ]
}
