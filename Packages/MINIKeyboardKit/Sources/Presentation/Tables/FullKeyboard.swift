/// The full-size keyboard of the Keys page, laid out as the cross-platform app's page: 15 key widths of
/// main block, the navigation keys and the keypad, with the Mac's modifiers in the bottom row.
enum FullKeyboard {
    /// A row's width in key widths: 15, a quarter, 3 of navigation, a quarter, 4 of keypad.
    static let width = 22.5

    struct Place {
        let face: BoardCap.Face
        let row: Int
        let column: Double
        let width: Double
    }

    /// Every cap, row by row from the left.
    static let places: [Place] = rows.enumerated().flatMap { row, slots in
        var column = 0.0
        return slots.compactMap { slot -> Place? in
            defer { column += slot.width }
            return switch slot {
            case .key(let usage, let width): Place(face: .key(KeyUsage.named(usage)!), row: row, column: column, width: width)
            case .modifier(let modifier, let width): Place(face: .modifier(modifier), row: row, column: column, width: width)
            case .gap: nil
            }
        }
    }

    private enum Slot {
        case key(UInt8, Double)
        case modifier(ModifierKey, Double)
        case gap(Double)

        var width: Double {
            switch self {
            case .key(_, let width), .modifier(_, let width), .gap(let width): width
            }
        }
    }

    private static func k(_ usage: UInt8, _ width: Double = 1) -> Slot { .key(usage, width) }
    private static func m(_ modifier: ModifierKey, _ width: Double) -> Slot { .modifier(modifier, width) }
    private static func keys(_ usages: UInt8...) -> [Slot] { usages.map { .key($0, 1) } }

    private static let rows: [[Slot]] = [
        [k(0x29), .gap(1)] + keys(0x3A, 0x3B, 0x3C, 0x3D) + [.gap(0.5)] + keys(0x3E, 0x3F, 0x40, 0x41) + [.gap(0.5)]
            + keys(0x42, 0x43, 0x44, 0x45) + [.gap(0.25)] + keys(0x46, 0x47, 0x48),
        keys(0x35, 0x1E, 0x1F, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x2D, 0x2E) + [k(0x2A, 2), .gap(0.25)]
            + keys(0x49, 0x4A, 0x4B) + [.gap(0.25)] + keys(0x53, 0x54, 0x55, 0x56),
        [k(0x2B, 1.5)] + keys(0x14, 0x1A, 0x08, 0x15, 0x17, 0x1C, 0x18, 0x0C, 0x12, 0x13, 0x2F, 0x30) + [k(0x31, 1.5), .gap(0.25)]
            + keys(0x4C, 0x4D, 0x4E) + [.gap(0.25)] + keys(0x5F, 0x60, 0x61, 0x57),
        [k(0x39, 1.75)] + keys(0x04, 0x16, 0x07, 0x09, 0x0A, 0x0B, 0x0D, 0x0E, 0x0F, 0x33, 0x34) + [k(0x28, 2.25), .gap(3.5)]
            + keys(0x5C, 0x5D, 0x5E),
        [m(.shift, 2.25)] + keys(0x1D, 0x1B, 0x06, 0x19, 0x05, 0x11, 0x10, 0x36, 0x37, 0x38) + [m(.rightShift, 2.75), .gap(1.25)]
            + [k(0x52), .gap(1.25)] + keys(0x59, 0x5A, 0x5B, 0x58),
        [m(.control, 1.25), m(.option, 1.25), m(.command, 1.25), k(0x2C, 6.25), m(.rightCommand, 1.25), m(.rightOption, 1.25),
         k(0x65, 1.25), m(.rightControl, 1.25), .gap(0.25)] + keys(0x50, 0x51, 0x4F) + [.gap(0.25), k(0x62, 2), k(0x63)],
    ]
}
