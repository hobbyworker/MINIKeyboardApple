/// Bytes as the device log shows them, in hex.
enum PacketText {
    /// "03 FB FB FB" — the zero padding a report ends with left out, keeping its first byte.
    static func summary(_ bytes: [UInt8]) -> String {
        hex(bytes.prefix(summaryCount(bytes)))
    }

    /// How many bytes the summary shows.
    static func summaryCount(_ bytes: [UInt8]) -> Int {
        var end = bytes.count
        while end > 1 && bytes[end - 1] == 0 { end -= 1 }
        return end
    }

    /// Every byte, 16 to a row after the row's offset: "0010  00 00 00 …".
    static func rows(_ bytes: [UInt8]) -> [String] {
        stride(from: 0, to: bytes.count, by: 16).map { start in
            let offset = String(start, radix: 16, uppercase: true)
            let padded = String(repeating: "0", count: max(0, 4 - offset.count)) + offset
            return padded + "  " + hex(bytes[start..<min(start + 16, bytes.count)])
        }
    }

    static func hex(_ bytes: ArraySlice<UInt8>) -> String {
        bytes.map { String([digits[Int($0 >> 4)], digits[Int($0 & 0x0F)]]) }.joined(separator: " ")
    }

    private static let digits = Array("0123456789ABCDEF")
}
