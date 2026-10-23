import SwiftUI
import Presentation

// What the app calls things, in the user's language. The view model names nothing a user reads.

extension ControlTitle {
    var text: Text {
        switch self {
        case .key(let number):
            Text("Key \(number)")
        case .knob(let number, .rotateLeft):
            Text("Knob \(number) · Rotate left")
        case .knob(let number, .press):
            Text("Knob \(number) · Press")
        case .knob(let number, .rotateRight):
            Text("Knob \(number) · Rotate right")
        case .knob(let number, .pressRotateLeft):
            Text("Knob \(number) · Press and rotate left")
        case .knob(let number, .pressRotateRight):
            Text("Knob \(number) · Press and rotate right")
        }
    }
}

extension MediaChoice {
    var title: LocalizedStringResource {
        switch self {
        case .playPause: "Play/Pause"
        case .stop: "Stop"
        case .previousTrack: "Prev Song"
        case .nextTrack: "Next Song"
        case .mute: "Mute"
        case .volumeUp: "Volume+"
        case .volumeDown: "Volume-"
        case .brightnessUp: "Brightness+"
        case .brightnessDown: "Brightness-"
        case .bassUp: "Bass+"
        case .bassDown: "Bass-"
        case .trebleUp: "Treble+"
        case .trebleDown: "Treble-"
        case .mediaPlayer: "Media Player"
        case .email: "Email"
        case .calculator: "Calculator"
        case .myComputer: "My Computer"
        case .webHome: "Web Home"
        case .webBack: "Web Back"
        case .webForward: "Web Forward"
        case .webRefresh: "Web Refresh"
        }
    }

    var systemImage: String {
        switch self {
        case .playPause: "playpause.fill"
        case .stop: "stop.fill"
        case .previousTrack: "backward.end.fill"
        case .nextTrack: "forward.end.fill"
        case .mute: "speaker.slash.fill"
        case .volumeUp: "speaker.plus.fill"
        case .volumeDown: "speaker.minus.fill"
        case .brightnessUp: "sun.max.fill"
        case .brightnessDown: "sun.min.fill"
        case .bassUp: "b.circle.fill"
        case .bassDown: "b.circle"
        case .trebleUp: "t.circle.fill"
        case .trebleDown: "t.circle"
        case .mediaPlayer: "play.rectangle.fill"
        case .email: "envelope.fill"
        case .calculator: "plus.forwardslash.minus"
        case .myComputer: "desktopcomputer"
        case .webHome: "house.fill"
        case .webBack: "chevron.backward"
        case .webForward: "chevron.forward"
        case .webRefresh: "arrow.clockwise"
        }
    }
}

extension MouseChoice {
    var title: LocalizedStringResource {
        switch self {
        case .leftClick: "Mouse Left"
        case .middleClick: "Mouse Centre"
        case .rightClick: "Mouse Right"
        case .wheelUp: "Mouse wheel Up"
        case .wheelDown: "Mouse wheel Down"
        case .controlWheelUp: "Ctrl + Mouse wheel Up"
        case .controlWheelDown: "Ctrl + Mouse wheel Down"
        case .shiftWheelUp: "Shift + Mouse wheel Up"
        case .shiftWheelDown: "Shift + Mouse wheel Down"
        case .optionWheelUp: "Alt + Mouse wheel Up"
        case .optionWheelDown: "Alt + Mouse wheel Down"
        }
    }

    var systemImage: String {
        switch self {
        case .leftClick, .middleClick, .rightClick: "computermouse.fill"
        case .wheelUp, .controlWheelUp, .shiftWheelUp, .optionWheelUp: "arrow.up"
        case .wheelDown, .controlWheelDown, .shiftWheelDown, .optionWheelDown: "arrow.down"
        }
    }
}

extension ModifierKey {
    var title: LocalizedStringKey {
        switch self {
        case .control: "Control"
        case .option: "Option"
        case .shift: "Shift"
        case .command: "Command"
        case .rightControl: "Right Control"
        case .rightOption: "Right Option"
        case .rightShift: "Right Shift"
        case .rightCommand: "Right Command"
        }
    }
}

extension LEDColor {
    var title: LocalizedStringResource {
        switch self {
        case .red: "Red"
        case .orange: "Orange"
        case .yellow: "Yellow"
        case .green: "Green"
        case .cyan: "Cyan"
        case .blue: "Blue"
        case .purple: "Purple"
        }
    }

    var color: Color {
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
}

extension RGB {
    var color: Color {
        Color(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }
}

extension InterfaceRole {
    var title: LocalizedStringResource {
        switch self {
        case .keyboard: "Keyboard"
        case .mouse: "Mouse"
        case .media: "Multimedia"
        case .configuration: "Configuration Channel"
        case .other: "Other"
        }
    }
}

/// The 1189:8890's light modes, named for what they do on one with six keys and a knob. Other keyboards'
/// modes have numbers only — what they do hasn't been seen.
enum LightingModeNames {
    static func title(_ mode: Int, k8890: Bool) -> LocalizedStringResource {
        switch (k8890, mode) {
        case (true, 0): "Off"
        case (true, 1): "Blink Last Key"
        case (true, 2): "Running Light"
        default: "Mode \(mode)"
        }
    }

    static func detail(_ mode: Int) -> LocalizedStringResource? {
        switch mode {
        case 1: "The last key pressed keeps blinking, in a new color with each press."
        case 2: "A light runs across the keys in order, in a new color each round."
        default: nil
        }
    }

    static func systemImage(_ mode: Int) -> String {
        switch mode {
        case 0: "lightbulb.slash"
        case 1: "hand.tap"
        default: "arrow.forward.circle"
        }
    }
}

extension KeyGroup.Kind {
    var title: LocalizedStringKey {
        switch self {
        case .letters: "Letters"
        case .numbers: "Numbers"
        case .editing: "Editing"
        case .symbols: "Symbols"
        case .functionKeys: "Function Keys"
        case .navigation: "Navigation"
        case .numpad: "Numpad"
        }
    }
}

extension EditorTab {
    var title: LocalizedStringKey {
        switch self {
        case .keys: "Keys"
        case .media: "Multimedia"
        case .mouse: "Mouse"
        case .lighting: "LED"
        case .delay: "Delay"
        }
    }
}

extension Notice {
    var message: LocalizedStringResource {
        switch self {
        case .saved: "Saved to the keyboard."
        case .readComplete: "Read from the keyboard."
        case .nothingToSave: "Nothing to save — no key has changed."
        case .identifyFailed: "The keyboard couldn’t be asked what it is."
        case .readFailed: "Reading from the keyboard failed."
        case .writeFailed(let code): "Writing to the keyboard failed (\(String(format: "0x%08X", UInt32(bitPattern: code))))."
        case .keyboardGone: "The keyboard is no longer connected."
        case .full(let limit): "A key holds up to \(limit) presses."
        case .selectControlFirst: "Select a key or knob."
        case .modifiersOnlyAlone: "Modifiers alone make the key a modifier key, so they can’t go with other presses."
        case .needsColorKey(let keys): "Only keys 1–\(keys) have a color. Select one of them."
        case .unsupported: "This keyboard can’t do that."
        }
    }
}

extension ActionCaption {
    /// What a key cap shows: "⌘C", "Mute".
    var text: Text {
        switch self {
        case .unknown, .nothing: Text(verbatim: "")
        case .presses(let text): Text(verbatim: text)
        case .media(let key): Text(key.title)
        case .otherMedia(let usage): Text("Media Key \(String(format: "0x%03X", usage))")
        case .mouse(let action): Text(action.title)
        }
    }
}

extension KeyUsage {
    /// What the key is called, for its help tag. A key whose cap reads plainly — a letter, a digit, F5 —
    /// goes by its label.
    var name: Text {
        switch usage {
        case 0x28: Text("Return", comment: "A keyboard key")
        case 0x29: Text("Escape", comment: "A keyboard key")
        case 0x2A: Text("Delete (Backspace)", comment: "A keyboard key")
        case 0x2B: Text("Tab", comment: "A keyboard key")
        case 0x39: Text("Caps Lock", comment: "A keyboard key")
        case 0x65: Text("Menu Key", comment: "A keyboard key: the application or context menu key")
        case 0x46: Text("Print Screen", comment: "A keyboard key")
        case 0x47: Text("Scroll Lock", comment: "A keyboard key")
        case 0x49: Text("Insert", comment: "A keyboard key")
        case 0x4A: Text("Home", comment: "A keyboard key")
        case 0x4B: Text("Page Up", comment: "A keyboard key")
        case 0x4C: Text("Forward Delete", comment: "A keyboard key: deletes the character after the cursor")
        case 0x4D: Text("End", comment: "A keyboard key")
        case 0x4E: Text("Page Down", comment: "A keyboard key")
        case 0x4F: Text("Right Arrow", comment: "A keyboard key")
        case 0x50: Text("Left Arrow", comment: "A keyboard key")
        case 0x51: Text("Down Arrow", comment: "A keyboard key")
        case 0x52: Text("Up Arrow", comment: "A keyboard key")
        case 0x53: Text("Num Lock", comment: "A keyboard key")
        case 0x58: Text("Keypad Enter", comment: "A keyboard key")
        case 0x54...0x63: Text("Keypad \(Self.keypadSymbols[usage] ?? label)", comment: "A key of the numeric keypad: “Keypad 7”, “Keypad /”")
        case 0x32, 0x64: Text("Non-US Key \(label) \(shifted ?? "")", comment: "A key ISO keyboards have and US ones don’t: “Non-US Key # ~”")
        default: Text(verbatim: label)
        }
    }

    /// The keypad's operators as their keys are usually named, rather than as their caps show them.
    private static let keypadSymbols: [UInt8: String] = [0x54: "/", 0x55: "*", 0x56: "-", 0x57: "+"]
}

extension DeviceLogViewModel.Line.Event {
    var message: LocalizedStringResource {
        switch self {
        case .searching: "Looking for the keyboard"
        case .connected(let usb, let interface): "Connected to \(usb), interface \(interface)"
        case .needsPermission: "Input Monitoring is needed"
        case .openFailed(let code): "The keyboard couldn’t be opened (\(Self.hex(code)))."
        case .writeFailed(let code): "Writing to the keyboard failed (\(Self.hex(code)))."
        case .simulated(let id): "Simulated keyboard: \(id)"
        }
    }

    private static func hex(_ code: Int32) -> String {
        String(format: "0x%08X", UInt32(bitPattern: code))
    }
}

extension SimulatorChoice.Kind {
    var title: Text {
        switch self {
        case .k8890(let reportID):
            Text("Report ID \(reportID)")
        case .identified(let keys, let knobs, let type, let usb):
            Text("\(Text("Keys: \(keys) · Knobs: \(knobs) · Type \(type)")) · \(usb)")
        case .unidentified(let usb):
            Text("\(KeyboardInfo.Commands.unidentified.text) · \(usb)")
        }
    }
}

extension KeyboardInfo.Channel {
    /// "Interface 1 · OUT 0x02 · Report ID 3 · 65 bytes".
    var text: Text {
        let way = switch path {
        case .usb(let endpoint): Text(verbatim: String(format: "OUT 0x%02X", endpoint))
        case .hid: Text(verbatim: "HID")
        case .simulated: Text("Simulator")
        }
        return Text("Interface \(interface) · \(way) · \(Text("Report ID \(reportID)")) · \(Text("\(reportLength) bytes"))")
    }
}

extension KeyboardInfo.Commands {
    var text: Text {
        switch self {
        case .packets(let reportID): Text("8890 Packets · \(Text("Report ID \(reportID)"))")
        case .standard: Text("884x · Standard Firmware (Type 10)")
        case .legacy: Text("884x · Legacy Firmware")
        case .unidentified: Text("884x · Doesn’t Answer Identification")
        case .unknown: Text(verbatim: "—")
        }
    }
}
