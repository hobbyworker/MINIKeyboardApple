import Foundation

/// What writing to the keyboard needs from its USB descriptors, parsed from the raw bytes.
enum USBDescriptors {
    struct Endpoint: Equatable, Sendable {
        var address: UInt8
        var maxPacketSize: Int
    }

    struct Interface: Equatable, Sendable {
        /// Every interrupt OUT endpoint, in descriptor order.
        var outEndpoints: [Endpoint] = []
        /// From the interface's HID descriptor.
        var reportDescriptorLength: Int?

        var outEndpoint: Endpoint? { outEndpoints.first }

        /// The OUT endpoint at `address`, or the first one when there is none there.
        func outEndpoint(preferring address: UInt8?) -> Endpoint? {
            outEndpoints.first { $0.address == address } ?? outEndpoints.first
        }
    }

    /// Interface `number` (alternate setting 0) in a configuration descriptor, or nil when the
    /// configuration has no such interface.
    static func interface(_ number: Int, inConfiguration bytes: [UInt8]) -> Interface? {
        var found: Interface?
        var inside = false
        var offset = 0
        while offset + 2 <= bytes.count {
            let length = Int(bytes[offset])
            guard length >= 2, offset + length <= bytes.count else { break }
            let descriptor = bytes[offset..<offset + length]
            let at = { (index: Int) -> Int in Int(descriptor[descriptor.startIndex + index]) }
            switch bytes[offset + 1] {
            case 0x04 where length >= 9:  // interface
                inside = at(2) == number && at(3) == 0
                if inside { found = Interface() }
            case 0x21 where inside && length >= 9:  // HID: the first class descriptor is the report descriptor
                if at(6) == 0x22 { found?.reportDescriptorLength = at(7) | at(8) << 8 }
            case 0x05 where inside && length >= 7:  // endpoint
                let address = UInt8(at(2))
                let isInterrupt = at(3) & 0x03 == 0x03
                if isInterrupt, address & 0x80 == 0 {
                    found?.outEndpoints.append(Endpoint(address: address, maxPacketSize: (at(4) | at(5) << 8) & 0x7FF))
                }
            default:
                break
            }
            offset += length
        }
        return found
    }
}

/// The output report a HID report descriptor declares.
enum HIDReportDescriptor {
    struct OutputReport: Equatable, Sendable {
        /// 0 when the descriptor numbers no reports.
        var id: UInt8
        /// In bytes, without the report ID.
        var length: Int
    }

    /// The first output report in `bytes`, with its whole length (every Output item of that ID).
    static func firstOutputReport(in bytes: [UInt8]) -> OutputReport? {
        var reportSize = 0
        var reportCount = 0
        var reportID: UInt8 = 0
        var stack: [(Int, Int, UInt8)] = []
        var first: UInt8?
        var bits = 0
        forEachItem(in: bytes) { type, tag, value in
            switch (type, tag) {
            case (1, 0x7): reportSize = value
            case (1, 0x8): reportID = UInt8(truncatingIfNeeded: value)
            case (1, 0x9): reportCount = value
            case (1, 0xA): stack.append((reportSize, reportCount, reportID))
            case (1, 0xB): if let saved = stack.popLast() { (reportSize, reportCount, reportID) = saved }
            case (0, 0x9):  // Output
                if first == nil { first = reportID }
                if reportID == first { bits += reportSize * reportCount }
            default: break
            }
        }
        guard let first, bits > 0 else { return nil }
        return OutputReport(id: first, length: (bits + 7) / 8)
    }

    /// The first usage page the descriptor names — its top collection's. Vendor-defined from 0xFF00.
    static func usagePage(in bytes: [UInt8]) -> Int? {
        var page: Int?
        forEachItem(in: bytes) { type, tag, value in
            if page == nil, type == 1, tag == 0x0 { page = value }
        }
        return page
    }

    /// Calls `body` with every short item's type, tag and value. Long items are skipped.
    private static func forEachItem(in bytes: [UInt8], _ body: (UInt8, UInt8, Int) -> Void) {
        var offset = 0
        while offset < bytes.count {
            let prefix = bytes[offset]
            if prefix == 0xFE {  // long item: data size, tag, data
                guard offset + 1 < bytes.count else { break }
                offset += 3 + Int(bytes[offset + 1])
                continue
            }
            let size = [0, 1, 2, 4][Int(prefix & 0x03)]
            guard offset + 1 + size <= bytes.count else { break }
            var value = 0
            for index in 0..<size { value |= Int(bytes[offset + 1 + index]) << (8 * index) }
            body(prefix >> 2 & 0x03, prefix >> 4, value)
            offset += 1 + size
        }
    }
}
