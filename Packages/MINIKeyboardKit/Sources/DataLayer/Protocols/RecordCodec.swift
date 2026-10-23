import Domain

/// The records 884x keyboards store actions in, as the cross-platform app writes and reads them
/// (`PHY2_KEY_Value` and `PHY_KEY_Value`), and the `FE` record of keyboards that don't say which they take.
///
/// A record starts `<marker> <record> <layer + 1> <kind>`; the kind is 1 for key presses, 2 for a media
/// key, 3 for a mouse action, 5 for key presses after a wait (legacy format) and 8 for lights.
///
/// - Standard (64 bytes): `[5]` the entry count, then three-byte entries from `[6]` — the wait before the
///   entry in milliseconds, high byte first, and a code: a key usage, or `F1`–`F8` for a modifier held
///   until the next key.
/// - Legacy (50 bytes): `[4…5]` the wait, low byte first, `[9]` the count, then (modifiers, key) pairs from
///   `[10]`. Modifiers with no key after them sit in the pair after the last.
/// - `FE`: as legacy, without a wait.
enum RecordCodec {
    static let standardLength = 64
    static let legacyLength = 50
    static let standardEntries = 18
    static let legacyPairs = 20

    enum Kind: UInt8 {
        case keys = 1, media = 2, mouse = 3, delayedKeys = 5, lighting = 8
    }

    // MARK: - Encoding

    /// The record that stores `action` for the control in record `recordID` of `layer` (from 0).
    static func encode(_ action: KeyAction, recordID: Int, layer: Int, format: RecordFormat) throws(KeyboardDeviceError) -> [UInt8] {
        switch format {
        case .standard: try standard(action, recordID: recordID, layer: layer)
        case .legacy: try pairs(action, marker: 0xFD, recordID: recordID, layer: layer, length: legacyLength, keepsDelay: true)
        case .unidentified: try unidentified(action, recordID: recordID, layer: layer)
        }
    }

    static func standard(_ action: KeyAction, recordID: Int, layer: Int) throws(KeyboardDeviceError) -> [UInt8] {
        var record = header(0xFD, recordID: recordID, layer: layer, length: standardLength)
        switch action {
        case .unassigned:
            record[3] = Kind.keys.rawValue
        case .keys(let macro):
            record[3] = Kind.keys.rawValue
            var entries: [(delay: Int, code: UInt8)] = []
            for stroke in macro.strokes {
                let codes = modifierCodes(stroke.modifiers) + (stroke.isModifiersOnly ? [] : [stroke.key])
                for (index, code) in codes.enumerated() {
                    entries.append((index == 0 ? stroke.delay : 0, code))
                }
            }
            guard entries.count <= standardEntries else { throw .unsupported }
            record[5] = UInt8(entries.count)
            for (index, entry) in entries.enumerated() {
                let delay = UInt16(clamping: entry.delay)
                record[6 + 3 * index] = UInt8(delay >> 8)
                record[7 + 3 * index] = UInt8(delay & 0xFF)
                record[8 + 3 * index] = entry.code
            }
        case .media(let key):
            record[3] = Kind.media.rawValue
            record[5] = 2
            record[8] = UInt8(key.usage & 0xFF)
            record[11] = UInt8(key.usage >> 8)
        case .mouse(let mouse):
            record[3] = Kind.mouse.rawValue
            record[5] = 4
            record[8] = modifierCodes(mouse.modifiers).first ?? 0
            record[11] = mouse.buttons
            record[20] = mouse.wheel
        }
        return record
    }

    /// The legacy record, or with marker `FE` and no wait the record of an unidentified keyboard.
    static func pairs(
        _ action: KeyAction, marker: UInt8, recordID: Int, layer: Int, length: Int, keepsDelay: Bool
    ) throws(KeyboardDeviceError) -> [UInt8] {
        var record = header(marker, recordID: recordID, layer: layer, length: length)
        switch action {
        case .unassigned:
            record[3] = Kind.keys.rawValue
        case .keys(let macro):
            let delay = keepsDelay ? UInt16(clamping: macro.delay) : 0
            record[3] = delay > 0 ? Kind.delayedKeys.rawValue : Kind.keys.rawValue
            record[4] = UInt8(delay & 0xFF)
            record[5] = UInt8(delay >> 8)
            if macro.strokes.count == 1, macro.strokes[0].isModifiersOnly {
                record[10] = macro.strokes[0].modifiers.rawValue
            } else {
                guard macro.strokes.count <= legacyPairs, 10 + 2 * macro.strokes.count <= length else { throw .unsupported }
                record[9] = UInt8(macro.strokes.count)
                for (index, stroke) in macro.strokes.enumerated() {
                    record[10 + 2 * index] = stroke.modifiers.rawValue
                    record[11 + 2 * index] = stroke.key
                }
            }
        case .media(let key):
            record[3] = Kind.media.rawValue
            record[9] = 2
            record[10] = UInt8(key.usage & 0xFF)
            record[11] = UInt8(key.usage >> 8)
        case .mouse(let mouse):
            record[3] = Kind.mouse.rawValue
            record[9] = 1
            record[10] = mouse.modifiers.rawValue
            record[11] = mouse.buttons
            record[14] = mouse.wheel
        }
        return record
    }

    /// The `FE` record: the legacy form with these differences, which keyboards of the 1189:8840 kind are
    /// known to take — a media key has a count of 0, a wheel move a count of 3.
    static func unidentified(_ action: KeyAction, recordID: Int, layer: Int) throws(KeyboardDeviceError) -> [UInt8] {
        var record = try pairs(action, marker: 0xFE, recordID: recordID, layer: layer, length: standardLength, keepsDelay: false)
        switch action {
        case .media: record[9] = 0
        case .mouse(let mouse) where mouse.wheel != 0: record[9] = 3
        default: break
        }
        return record
    }

    /// A legacy-format layer's lights, which it keeps in record 0: `FE B0 <layer + 1> 08`, a count of 1 and
    /// `colour << 4 | mode` in `[11]`.
    static func legacyLighting(color: LightColor, mode: UInt8, layer: Int, length: Int = legacyLength) -> [UInt8] {
        var record = [UInt8](repeating: 0, count: length)
        record[0] = 0xFE
        record[1] = 0xB0
        record[2] = UInt8(layer + 1)
        record[3] = Kind.lighting.rawValue
        record[9] = 1
        record[11] = color.rawValue << 4 | (mode & 0x0F)
        return record
    }

    private static func header(_ marker: UInt8, recordID: Int, layer: Int, length: Int) -> [UInt8] {
        var record = [UInt8](repeating: 0, count: length)
        record[0] = marker
        record[1] = UInt8(recordID)
        record[2] = UInt8(layer + 1)
        return record
    }

    /// `F1`–`F8` for the modifiers set, lowest bit first: left Control, Shift, Option, Command, then right.
    static func modifierCodes(_ modifiers: Modifiers) -> [UInt8] {
        Modifiers.each.enumerated().compactMap { bit, modifier in
            modifiers.contains(modifier) ? 0xF1 + UInt8(bit) : nil
        }
    }

    static func modifiers(fromCode code: UInt8) -> Modifiers? {
        (0xF1...0xF8).contains(code) ? Modifiers(rawValue: 1 << (code - 0xF1)) : nil
    }

    // MARK: - Decoding

    /// The action a record the keyboard reported stores, or nil for a kind the app doesn't know.
    static func decode(_ record: [UInt8], format: RecordFormat) -> KeyAction? {
        let byte = { (index: Int) -> UInt8 in record.indices.contains(index) ? record[index] : 0 }
        guard let kind = Kind(rawValue: byte(3)) else { return byte(3) == 0 ? .unassigned : nil }
        switch (format, kind) {
        case (.standard, .keys), (.standard, .delayedKeys):
            var strokes: [KeyStroke] = []
            var held: Modifiers = []
            var heldDelay: Int?
            for index in 0..<min(Int(byte(5)), standardEntries) {
                let code = byte(8 + 3 * index)
                let delay = Int(byte(6 + 3 * index)) << 8 | Int(byte(7 + 3 * index))
                if let modifier = modifiers(fromCode: code) {
                    held.insert(modifier)
                    heldDelay = heldDelay ?? delay
                } else if code != 0 {
                    strokes.append(KeyStroke(modifiers: held, key: code, delay: heldDelay ?? delay))
                    held = []
                    heldDelay = nil
                }
            }
            if !held.isEmpty, strokes.isEmpty { strokes.append(KeyStroke(modifiers: held, key: 0, delay: heldDelay ?? 0)) }
            return strokes.isEmpty ? .unassigned : .keys(KeyMacro(strokes))
        case (_, .keys), (_, .delayedKeys):
            let delay = kind == .delayedKeys ? Int(byte(4)) | Int(byte(5)) << 8 : 0
            let count = min(Int(byte(9)), legacyPairs)
            var strokes = (0..<count).compactMap { index -> KeyStroke? in
                let modifiers = Modifiers(rawValue: byte(10 + 2 * index)), key = byte(11 + 2 * index)
                return modifiers.isEmpty && key == 0 ? nil : KeyStroke(modifiers: modifiers, key: key)
            }
            if count == 0, byte(10) != 0 { strokes = [KeyStroke(modifiers: Modifiers(rawValue: byte(10)), key: 0)] }
            if strokes.count > 1 { strokes.removeAll(where: \.isModifiersOnly) }
            return strokes.isEmpty && delay == 0 ? .unassigned : .keys(KeyMacro(strokes, delay: delay))
        case (.standard, .media):
            let usage = UInt16(byte(8)) | UInt16(byte(11)) << 8
            return usage == 0 ? .unassigned : .media(MediaKey(usage: usage))
        case (_, .media):
            let usage = UInt16(byte(10)) | UInt16(byte(11)) << 8
            return usage == 0 ? .unassigned : .media(MediaKey(usage: usage))
        case (.standard, .mouse):
            return mouse(buttons: byte(11), wheel: byte(20), modifiers: modifiers(fromCode: byte(8)) ?? [])
        case (_, .mouse):
            let held = Modifiers(rawValue: byte(10)).members.first ?? []
            return mouse(buttons: byte(11), wheel: byte(14), modifiers: held)
        case (_, .lighting):
            return nil
        }
    }

    private static func mouse(buttons: UInt8, wheel: UInt8, modifiers: Modifiers) -> KeyAction? {
        if buttons == 0, wheel == 0 { return .unassigned }
        return MouseAction(buttons: buttons, wheel: wheel, modifiers: modifiers).map(KeyAction.mouse)
    }
}
