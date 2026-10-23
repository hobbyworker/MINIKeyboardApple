import Foundation
import Domain

// What the screens offer and show, in their own words. The domain's types stay behind the view model: views
// hand these back, and the view model turns them into the domain's.

/// A modifier key, as the Keys page offers it.
public enum ModifierKey: CaseIterable, Hashable, Sendable {
    case control, option, shift, command, rightControl, rightOption, rightShift, rightCommand

    /// "⌃", or "R⌃" for a right-hand one.
    public var symbol: String {
        switch self {
        case .control: "⌃"
        case .option: "⌥"
        case .shift: "⇧"
        case .command: "⌘"
        case .rightControl: "R⌃"
        case .rightOption: "R⌥"
        case .rightShift: "R⇧"
        case .rightCommand: "R⌘"
        }
    }

    var modifiers: Modifiers {
        switch self {
        case .control: .control
        case .option: .option
        case .shift: .shift
        case .command: .command
        case .rightControl: .rightControl
        case .rightOption: .rightOption
        case .rightShift: .rightShift
        case .rightCommand: .rightCommand
        }
    }
}

/// A media key the app names.
public enum MediaChoice: CaseIterable, Hashable, Sendable {
    case playPause, stop, previousTrack, nextTrack, mute, volumeUp, volumeDown, brightnessUp, brightnessDown
    case bassUp, bassDown, trebleUp, trebleDown, mediaPlayer, email, calculator, myComputer
    case webHome, webBack, webForward, webRefresh

    var key: MediaKey {
        switch self {
        case .playPause: .playPause
        case .stop: .stop
        case .previousTrack: .previousTrack
        case .nextTrack: .nextTrack
        case .mute: .mute
        case .volumeUp: .volumeUp
        case .volumeDown: .volumeDown
        case .brightnessUp: .brightnessUp
        case .brightnessDown: .brightnessDown
        case .bassUp: .bassUp
        case .bassDown: .bassDown
        case .trebleUp: .trebleUp
        case .trebleDown: .trebleDown
        case .mediaPlayer: .mediaPlayer
        case .email: .email
        case .calculator: .calculator
        case .myComputer: .myComputer
        case .webHome: .webHome
        case .webBack: .webBack
        case .webForward: .webForward
        case .webRefresh: .webRefresh
        }
    }

    init?(_ key: MediaKey) {
        guard let choice = Self.allCases.first(where: { $0.key == key }) else { return nil }
        self = choice
    }
}

/// A mouse action.
public enum MouseChoice: CaseIterable, Hashable, Sendable {
    case leftClick, middleClick, rightClick
    case wheelUp, wheelDown
    case controlWheelUp, controlWheelDown
    case shiftWheelUp, shiftWheelDown
    case optionWheelUp, optionWheelDown

    var action: MouseAction {
        switch self {
        case .leftClick: .leftClick
        case .middleClick: .middleClick
        case .rightClick: .rightClick
        case .wheelUp: .wheelUp
        case .wheelDown: .wheelDown
        case .controlWheelUp: .controlWheelUp
        case .controlWheelDown: .controlWheelDown
        case .shiftWheelUp: .shiftWheelUp
        case .shiftWheelDown: .shiftWheelDown
        case .optionWheelUp: .optionWheelUp
        case .optionWheelDown: .optionWheelDown
        }
    }

    init(_ action: MouseAction) {
        self = Self.allCases.first { $0.action == action }!
    }
}

/// A colour a layer of a legacy-format or unidentified keyboard lights in.
public enum LEDColor: CaseIterable, Hashable, Sendable {
    case red, orange, yellow, green, cyan, blue, purple

    var color: LightColor {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .cyan: .cyan
        case .blue: .blue
        case .purple: .purple
        }
    }

    init(_ color: LightColor) {
        self = Self.allCases.first { $0.color == color }!
    }
}

/// A key's colour on a keyboard that lights each key.
public struct RGB: Hashable, Sendable {
    public let red: UInt8
    public let green: UInt8
    public let blue: UInt8

    public init(red: UInt8, green: UInt8, blue: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    init(_ color: KeyColor) {
        self.init(red: color.red, green: color.green, blue: color.blue)
    }

    var keyColor: KeyColor { KeyColor(red: red, green: green, blue: blue) }

    /// "#00FF00".
    public var hex: String { String(format: "#%02X%02X%02X", red, green, blue) }
}

/// One action of a knob.
public enum KnobAction: CaseIterable, Hashable, Sendable {
    case rotateLeft, press, rotateRight, pressRotateLeft, pressRotateRight

    init(_ part: KnobPart) {
        self = switch part {
        case .rotateLeft: .rotateLeft
        case .press: .press
        case .rotateRight: .rotateRight
        case .pressRotateLeft: .pressRotateLeft
        case .pressRotateRight: .pressRotateRight
        }
    }

    var part: KnobPart {
        switch self {
        case .rotateLeft: .rotateLeft
        case .press: .press
        case .rotateRight: .rotateRight
        case .pressRotateLeft: .pressRotateLeft
        case .pressRotateRight: .pressRotateRight
        }
    }
}

/// What a control is called: "Key 3", "Knob 1 · Press".
public enum ControlTitle: Hashable, Sendable {
    case key(Int)
    case knob(Int, KnobAction)
}

/// A key or knob action on the keyboard, as views hand it back to the view model.
public struct ControlRef: Hashable, Sendable {
    let id: ControlID

    init(_ id: ControlID) {
        self.id = id
    }

    public static func key(_ number: Int) -> ControlRef {
        ControlRef(.key(number: number))
    }

    public static func knob(_ number: Int, _ action: KnobAction) -> ControlRef {
        ControlRef(.knob(number: number, part: action.part))
    }

    public var title: ControlTitle {
        switch id {
        case .key(let number): .key(number)
        case .knob(let number, let part): .knob(number, KnobAction(part))
        }
    }
}

/// What a key does, as a key cap and the inspector show it.
public enum ActionCaption: Hashable, Sendable {
    /// The app doesn't know: the keyboard can't be read, or nobody has set it.
    case unknown
    case nothing
    /// "⌘C ↩".
    case presses(String)
    case media(MediaChoice)
    /// A media key the app has no name for, by its consumer usage.
    case otherMedia(UInt16)
    case mouse(MouseChoice)

    public var isAssigned: Bool {
        switch self {
        case .unknown, .nothing: false
        default: true
        }
    }

    init(_ action: KeyAction?) {
        switch action {
        case nil: self = .unknown
        case .unassigned?: self = .nothing
        case .keys(let macro)?: self = macro.strokes.isEmpty ? .nothing : .presses(ActionText.keys(macro))
        case .media(let key)?: self = MediaChoice(key).map(ActionCaption.media) ?? .otherMedia(key.usage)
        case .mouse(let action)?: self = .mouse(MouseChoice(action))
        }
    }
}
