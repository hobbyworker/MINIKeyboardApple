import Foundation

/// The arrangement of a keyboard whose shape no vendor tool draws — the 1189:8890's Windows tool shows the
/// same panel of buttons for every keyboard. It says only what is known: how many keys, how many to a row,
/// how many knobs. A schematic, not the keyboard's real shape.
public struct GridShape: Hashable, Sendable {
    public let keys: Int
    public let columns: Int
    public let knobs: Int

    public init?(keys: Int, columns: Int, knobs: Int) {
        guard keys >= 0, knobs >= 0, keys + knobs > 0, (1...max(keys, 1)).contains(columns) else { return nil }
        self.keys = keys
        self.columns = columns
        self.knobs = knobs
    }

    /// "grid-6-3-1": six keys, three to a row, one knob.
    public var id: String { "grid-\(keys)-\(columns)-\(knobs)" }

    public init?(id: String) {
        let parts = id.split(separator: "-")
        guard parts.count == 4, parts[0] == "grid", let keys = Int(parts[1]), let columns = Int(parts[2]),
              let knobs = Int(parts[3])
        else { return nil }
        self.init(keys: keys, columns: columns, knobs: knobs)
    }

    public var rows: Int { keys == 0 ? 0 : (keys + columns - 1) / columns }

    /// The arrangement's controls: keys 1… filling the rows from the top left, then each knob's three
    /// actions.
    public var layout: KeyboardLayout {
        let keyControls = (0..<keys).map { ControlID.key(number: $0 + 1) }
        let knobControls = (0..<knobs).flatMap { knob in
            [KnobPart.rotateLeft, .press, .rotateRight].map { ControlID.knob(number: knob + 1, part: $0) }
        }
        return KeyboardLayout(id: id, controls: keyControls + knobControls)
    }
}

/// How large an arrangement a keyboard can have.
public struct GridLimits: Hashable, Sendable {
    public let maxKeys: Int
    public let maxKnobs: Int

    public func contains(_ shape: GridShape) -> Bool {
        shape.keys <= maxKeys && shape.knobs <= maxKnobs
    }

    /// What the vendor's Windows tool can program: twelve keys and two knobs. Until the user says otherwise,
    /// a 1189:8890 is drawn that large, four to a row as the tool's panel has them.
    public static let k8890 = GridLimits(maxKeys: 12, maxKnobs: 2)

    public var assumed: GridShape {
        GridShape(keys: maxKeys, columns: min(4, max(maxKeys, 1)), knobs: maxKnobs)!
    }
}
