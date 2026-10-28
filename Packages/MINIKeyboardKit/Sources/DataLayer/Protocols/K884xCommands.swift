import Domain

/// The 884x keyboards' requests and answers, as the cross-platform app sends and reads them. Every
/// request is a 64-byte payload after report ID 3; every answer a 64-byte input report, its first byte
/// the report ID.
enum K884xCommands {
    static let reportID: UInt8 = 0x03
    /// The report ID and 64 bytes.
    static let reportLength = 65

    /// `FB FB FB`: how many keys and knobs, and the type (`Widget::Read_KeyBoard_KeyNum`).
    static let identify: [UInt8] = [0xFB, 0xFB, 0xFB]

    /// `FD FE FF`: keep what was written. The app waits 200 ms after it.
    static let commit: [UInt8] = [0xFD, 0xFE, 0xFF]
    static let commitPause: Duration = .milliseconds(200)

    /// `FA <records> <knob records> <layer + 1>` — the standard format reads its 25 records (`Read_CurKeyBoard_Data`),
    /// the legacy one all 24 — 15 keys, then 3 knobs of 3 — as `FA 18 00`. The cross-platform app asks `FA 0F 03`
    /// (`Read_configuration_clicked`) and waits for 24, but a legacy keyboard answers as many records as the first
    /// number says (514C:8850, type 11: 15). Counted either way, `FA 18 00` comes to 24.
    static func readRecords(layer: Int, format: RecordFormat) -> [UInt8]? {
        switch format {
        case .standard: [0xFA, 25, 0, UInt8(layer + 1)]
        case .legacy: [0xFA, 24, 0, UInt8(layer + 1)]
        case .unidentified: nil
        }
    }

    /// How many answers follow `readRecords`, one record each, records 1… in order.
    static func readReplyCount(_ format: RecordFormat) -> Int {
        format == .standard ? 25 : 15 + 3 * 3
    }

    /// `FA B0 <layer>`: one layer's lights (standard format, `Read_RgbLed_DataDsp`). The layer counts from 0.
    static func readLighting(layer: Int) -> [UInt8] {
        [0xFA, 0xB0, UInt8(layer)]
    }

    /// `FE B0 <layer> <mode> <r g b × 16>` (standard format). The layer counts from 0.
    static func lighting(layer: Int, mode: UInt8, colors: [KeyColor]) -> [UInt8] {
        var payload: [UInt8] = [0xFE, 0xB0, UInt8(layer), mode]
        for color in colors.prefix(LightingSupport.colorKeyCount) {
            payload += [color.red, color.green, color.blue]
        }
        return payload
    }

    // MARK: - Answers (the report ID first)

    static func identity(from reply: [UInt8]) -> KeyboardIdentity? {
        guard reply.count >= 5 else { return nil }
        return KeyboardIdentity(keyCount: Int(reply[2]), knobCount: Int(reply[3]), type: Int(reply[4]))
    }

    /// A record answer carries the record after the report ID.
    static func record(from reply: [UInt8]) -> [UInt8] {
        Array(reply.dropFirst())
    }

    /// `[2]` the mode, `[3…50]` sixteen colours.
    static func lighting(from reply: [UInt8]) -> LayerLighting? {
        let count = LightingSupport.colorKeyCount
        guard reply.count >= 3 + 3 * count else { return nil }
        let colors = (0..<count).map { KeyColor(red: reply[3 + 3 * $0], green: reply[4 + 3 * $0], blue: reply[5 + 3 * $0]) }
        return .perKey(mode: reply[2], colors: colors)
    }

    // MARK: - Unidentified keyboards

    /// After an `FE` record: `AA AA`, `FD FE FF`, `AA AA`.
    static let unidentifiedSave: [[UInt8]] = [[0xAA, 0xAA], commit, [0xAA, 0xAA]]

    /// Lights of an unidentified keyboard: `FE B0 <layer + 1> 08 … 01 00 <code>` and the commit, after the
    /// identification and reads the cross-platform app sends first on the same connection — without them
    /// the light is known to change but not to stay.
    static func unidentifiedLighting(color: LightColor, mode: UInt8, layer: Int) -> [[UInt8]] {
        [[0xFB, 0xFB, 0xFB, 0x01]]
            + (1...3).map { [0xFA, 0x0F, 0x03, UInt8($0), 0x7F] }
            + [Array(RecordCodec.legacyLighting(color: color, mode: mode, layer: layer, length: 12)), commit]
    }
}
