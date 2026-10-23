import Domain

/// The 1189:8890's commands, as the vendor's Windows tool sends them (`FormMain.Download_Click`,
/// `Send_SwLayer`, `Send_WriteFlash_Cmd`, `Send_WriteFlashLED_Cmd`). Every packet is eight bytes after the
/// report ID; the keyboard answers none of them.
///
/// One key is written as the layer switch `A1 <layer>`, the key's packets and `AA AA`; lights as the
/// layer switch, `B0 <type> <mode>` and `AA A1`. On report ID 0 there is no layer switch and no layer
/// in the type byte.
enum K8890Packets {
    static let payloadLength = 8

    static func pad(_ bytes: [UInt8]) -> [UInt8] {
        bytes + [UInt8](repeating: 0, count: max(payloadLength - bytes.count, 0))
    }

    /// Type nibbles (`KeyParam.KeyType_Num`).
    enum Kind: UInt8 {
        case keys = 1, media = 2, mouse = 3, lighting = 8
    }

    /// A key's packets and the save that follows. `layer` counts from 0.
    static func download(number: UInt8, action: KeyAction, layer: Int, reportID: UInt8) throws(KeyboardDeviceError) -> [[UInt8]] {
        layerSwitch(layer, reportID: reportID)
            + (try keyPackets(number: number, action: action, layer: layer, reportID: reportID))
            + [pad([0xAA, 0xAA])]
    }

    static func downloadLighting(mode: UInt8, layer: Int, reportID: UInt8) -> [[UInt8]] {
        layerSwitch(layer, reportID: reportID)
            + [pad([0xB0, typeByte(.lighting, layer: layer, reportID: reportID), mode])]
            + [pad([0xAA, 0xA1])]
    }

    static func layerSwitch(_ layer: Int, reportID: UInt8) -> [[UInt8]] {
        reportID == 0 ? [] : [pad([0xA1, UInt8(layer + 1)])]
    }

    /// `(layer << 4) | kind`, or the kind alone on report ID 0.
    static func typeByte(_ kind: Kind, layer: Int, reportID: UInt8) -> UInt8 {
        reportID == 0 ? kind.rawValue : UInt8(layer + 1) << 4 | kind.rawValue
    }

    /// A key press list is `count + 1` packets: the first carries the first press's modifiers, the rest
    /// one (modifiers, key) group each. A key with modifiers alone has no group, its modifiers in the first
    /// packet; a cleared key has nothing at all.
    static func keyPackets(number: UInt8, action: KeyAction, layer: Int, reportID: UInt8) throws(KeyboardDeviceError) -> [[UInt8]] {
        switch action {
        case .unassigned:
            let type = typeByte(.keys, layer: layer, reportID: reportID)
            return [[number, type, 0, 0, 0, 0, 0, 0]]
        case .keys(let macro):
            let type = typeByte(.keys, layer: layer, reportID: reportID)
            let groups = macro.strokes.filter { !$0.isModifiersOnly }
            guard groups.count <= 5 else { throw .unsupported }
            let first = macro.strokes.first?.modifiers ?? []
            let count = UInt8(groups.count)
            var packets = [[number, type, count, 0, first.rawValue, 0, 0, 0]]
            for (index, group) in groups.enumerated() {
                packets.append([number, type, count, UInt8(index + 1), group.modifiers.rawValue, group.key, 0, 0])
            }
            return packets
        case .media(let key):
            guard let (low, high) = mediaBytes(key, reportID: reportID) else { throw .unsupported }
            return [[number, typeByte(.media, layer: layer, reportID: reportID), low, high, 0, 0, 0, 0]]
        case .mouse(let action):
            return [[number, typeByte(.mouse, layer: layer, reportID: reportID), action.buttons, 0, 0,
                     action.wheel, action.modifiers.rawValue, 0]]
        }
    }

    /// The two bytes of a media key. Report ID 3 takes the consumer usage; the other two take codes of
    /// their own, known for the Windows tool's six keys only.
    static func mediaBytes(_ key: MediaKey, reportID: UInt8) -> (UInt8, UInt8)? {
        switch reportID {
        case 0: reportID0[key]
        case 2: reportID2[key]
        default: (UInt8(key.usage & 0xFF), UInt8(key.usage >> 8))
        }
    }

    private static let reportID0: [MediaKey: (UInt8, UInt8)] = [
        .playPause: (0x40, 0x00), .previousTrack: (0x80, 0x00), .nextTrack: (0x00, 0x01),
        .mute: (0x04, 0x00), .volumeUp: (0x02, 0x00), .volumeDown: (0x01, 0x00),
    ]

    private static let reportID2: [MediaKey: (UInt8, UInt8)] = [
        .playPause: (0x00, 0x04), .previousTrack: (0x00, 0x0B), .nextTrack: (0x00, 0x0A),
        .mute: (0x00, 0x01), .volumeUp: (0x40, 0x00), .volumeDown: (0x80, 0x00),
    ]
}

/// How the 1189:8890 numbers its controls: keys 1–12, then three actions to a knob from 13 — turn left,
/// press, turn right. The Windows tool has no number for a third knob, or for turning a knob pressed
/// (`KeyboardCapabilities.canAddress` says the same in the domain's words).
enum K8890Numbering {
    static func number(of control: ControlID) -> UInt8? {
        switch control {
        case .key(let number):
            (1...12).contains(number) ? UInt8(number) : nil
        case .knob(let number, let part):
            (1...2).contains(number) && part <= .rotateRight ? UInt8(13 + (number - 1) * 3 + part.rawValue) : nil
        }
    }
}
