import Foundation
import Domain

/// The pages of actions a key can be given.
public enum EditorTab: String, CaseIterable, Identifiable, Sendable {
    case keys, media, mouse, lighting, delay

    public var id: String { rawValue }
}

/// A transfer with the keyboard under way.
public enum Activity: Hashable, Sendable {
    case identifying, reading, saving
}

/// A message that comes and goes.
public enum Notice: Hashable, Sendable {
    /// Saved; to a simulated keyboard when `simulated` — nothing went to a real one.
    case saved(simulated: Bool)
    case readComplete
    case nothingToSave
    case identifyFailed
    case readFailed
    /// The IOReturn code of the failed write.
    case writeFailed(Int32)
    case keyboardGone
    case full(Int)
    case selectControlFirst
    case modifiersOnlyAlone
    case needsColorKey(Int)
    case unsupported

    public var isError: Bool {
        switch self {
        case .saved, .readComplete, .nothingToSave: false
        default: true
        }
    }

    /// How long it stays.
    public var lifetime: Duration {
        if isError { return .seconds(6) }
        if case .saved(simulated: true) = self { return .seconds(4) }
        return .seconds(2.5)
    }
}

/// How actions read on key caps and in lists: macOS's modifier symbols, then the key.
public enum ActionText {
    /// "⌃⌥⇧⌘", in the order macOS writes them; a right-hand modifier is marked "R".
    public static func modifiers(_ modifiers: Modifiers) -> String {
        let order: [(Modifiers, Modifiers, String)] = [
            (.control, .rightControl, "⌃"), (.option, .rightOption, "⌥"), (.shift, .rightShift, "⇧"),
            (.command, .rightCommand, "⌘"),
        ]
        return order.map { left, right, symbol in
            (modifiers.contains(left) ? symbol : "") + (modifiers.contains(right) ? "R" + symbol : "")
        }
        .joined()
    }

    /// "⌘C", or "⌃⇧" for modifiers alone.
    public static func stroke(_ stroke: KeyStroke) -> String {
        modifiers(stroke.modifiers) + (stroke.isModifiersOnly ? "" : key(stroke.key))
    }

    /// The presses one after another.
    public static func keys(_ macro: KeyMacro) -> String {
        macro.strokes.map(stroke).joined(separator: " ")
    }

    /// A key's label, or its usage in hex when the app has no name for it.
    public static func key(_ usage: UInt8) -> String {
        KeyUsage.named(usage)?.label ?? String(format: "0x%02X", usage)
    }
}
