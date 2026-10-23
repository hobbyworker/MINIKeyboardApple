import Domain

/// A rectangle in a layout's drawing space.
public struct LayoutRect: Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var width: Double
    public var height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var maxX: Double { x + width }
    public var maxY: Double { y + height }
    public var midX: Double { x + width / 2 }
    public var midY: Double { y + height / 2 }
}

/// Where a layout's controls are drawn, and the keyboard's body around them.
struct LayoutGeometry: Hashable, Sendable {
    var frame: LayoutRect
    var rects: [ControlID: LayoutRect]

    /// The cross-platform app's own geometry for its layouts; an arrangement's is drawn from its counts.
    static func of(_ layout: KeyboardLayout) -> LayoutGeometry? {
        if let shape = GridShape(id: layout.id) { return LayoutGeometry(arrangement: shape) }
        return app[layout.id]
    }

    /// The body and every control.
    var bounds: LayoutRect {
        var minX = frame.x, minY = frame.y, maxX = frame.maxX, maxY = frame.maxY
        for rect in rects.values {
            minX = min(minX, rect.x)
            minY = min(minY, rect.y)
            maxX = max(maxX, rect.maxX)
            maxY = max(maxY, rect.maxY)
        }
        return LayoutRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// As it looks with the keyboard turned: every rectangle turned about the middle of the bounds. Squares
    /// stay squares; a wide key stands up.
    func rotated(_ rotation: Rotation) -> LayoutGeometry {
        guard rotation != .upright else { return self }
        let bounds = bounds
        let centerX = bounds.midX, centerY = bounds.midY
        func turn(_ rect: LayoutRect) -> LayoutRect {
            let dx = rect.midX - centerX, dy = rect.midY - centerY
            let (x, y): (Double, Double) = switch rotation {
            case .upright: (dx, dy)
            case .quarter: (-dy, dx)
            case .half: (-dx, -dy)
            case .threeQuarters: (dy, -dx)
            }
            let sideways = rotation == .quarter || rotation == .threeQuarters
            let width = sideways ? rect.height : rect.width
            let height = sideways ? rect.width : rect.height
            return LayoutRect(x: centerX + x - width / 2, y: centerY + y - height / 2, width: width, height: height)
        }
        return LayoutGeometry(frame: turn(frame), rects: rects.mapValues(turn))
    }

    /// Each knob as one body, for drawing the keyboard's shape — its actions are separate controls only for
    /// binding. The body sits on the press action, as large as it; a knob without one sits between its
    /// turns, as large as the layout's other knobs.
    var knobOutlines: [(number: Int, rect: LayoutRect)] {
        var parts: [Int: [(part: KnobPart, rect: LayoutRect)]] = [:]
        for (control, rect) in rects {
            if case .knob(let number, let part) = control { parts[number, default: []].append((part, rect)) }
        }
        let pressSize = parts.values.flatMap { $0 }.filter { $0.part == .press }.map(\.rect.width).max()
        return parts.keys.sorted().map { number in
            let rects = parts[number]!
            if let press = rects.first(where: { $0.part == .press })?.rect { return (number, press) }
            let minX = rects.map(\.rect.x).min()!, maxX = rects.map(\.rect.maxX).max()!
            let minY = rects.map(\.rect.y).min()!, maxY = rects.map(\.rect.maxY).max()!
            let size = pressSize ?? min(maxX - minX, maxY - minY)
            return (number, LayoutRect(x: (minX + maxX - size) / 2, y: (minY + maxY - size) / 2, width: size, height: size))
        }
    }
}

extension LayoutGeometry {
    // An arrangement's sizes, in the same space as the app's layouts: a key 100 wide.
    private static let key = 100.0, keyGap = 20.0
    private static let press = 80.0, turn = 44.0, turnOffset = 72.0
    private static let knobGap = 30.0, knobSpacing = 110.0, margin = 40.0

    /// An arrangement drawn tidily, since the keyboard's real shape is not known: keys fill the rows from the
    /// top left; knobs stand to the right of the keys — one at their middle, two at the first and last rows
    /// (or around the middle when the rows are too close) — each with its turns either side of its press.
    init(arrangement shape: GridShape) {
        let pitch = Self.key + Self.keyGap
        var rects: [ControlID: LayoutRect] = [:]
        for index in 0..<shape.keys {
            rects[.key(number: index + 1)] = LayoutRect(
                x: Double(index % shape.columns) * pitch, y: Double(index / shape.columns) * pitch,
                width: Self.key, height: Self.key)
        }
        let blockWidth = shape.keys == 0 ? 0 : Double(shape.columns) * pitch - Self.keyGap
        let blockHeight = shape.keys == 0 ? Self.press : Double(shape.rows) * pitch - Self.keyGap
        let knobWidth = 2 * Self.turnOffset + Self.turn
        for index in 0..<shape.knobs {
            let center: (x: Double, y: Double)
            if shape.keys == 0 {
                center = (knobWidth / 2 + Double(index) * (knobWidth + Self.knobGap), blockHeight / 2)
            } else {
                let first = Self.key / 2, last = blockHeight - Self.key / 2
                let y: Double = switch shape.knobs {
                case 1: blockHeight / 2
                default: last - first >= Self.knobSpacing
                    ? first + (last - first) * Double(index) / Double(shape.knobs - 1)
                    : blockHeight / 2 + (Double(index) - Double(shape.knobs - 1) / 2) * Self.knobSpacing
                }
                center = (blockWidth + Self.knobGap + knobWidth / 2, y)
            }
            for (part, offset, size) in [(KnobPart.rotateLeft, -Self.turnOffset, Self.turn), (.press, 0, Self.press),
                                         (.rotateRight, Self.turnOffset, Self.turn)] {
                rects[.knob(number: index + 1, part: part)] = LayoutRect(
                    x: center.x + offset - size / 2, y: center.y - size / 2, width: size, height: size)
            }
        }
        let all = Array(rects.values)
        let minX = all.map(\.x).min() ?? 0, minY = all.map(\.y).min() ?? 0
        let maxX = all.map(\.maxX).max() ?? 0, maxY = all.map(\.maxY).max() ?? 0
        frame = LayoutRect(x: minX - Self.margin, y: minY - Self.margin,
                           width: maxX - minX + 2 * Self.margin, height: maxY - minY + 2 * Self.margin)
        self.rects = rects
    }
}
