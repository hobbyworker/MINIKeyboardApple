/// What a connected keyboard can hold and do, from the commands it takes.
public struct KeyboardCapabilities: Hashable, Sendable {
    public let commands: CommandSet

    public init(commands: CommandSet) {
        self.commands = commands
    }

    /// The 8890 with report ID 0 takes no layer command; every other keyboard has three layers.
    public var layerCount: Int {
        commands == .packets(reportID: 0) ? 1 : 3
    }

    /// How many presses one key holds — counted as `presses(in:)` counts them.
    public var pressLimit: Int {
        switch commands {
        case .packets: 5
        case .records(.standard): 18
        case .records(.legacy): 20
        case .records(.unidentified): 18
        }
    }

    /// Whether each modifier takes a place of its own, as in the standard format.
    public var modifiersTakePlaces: Bool {
        commands == .records(.standard)
    }

    /// The places `macro` takes in a key.
    public func presses(in macro: KeyMacro) -> Int {
        guard modifiersTakePlaces else { return macro.strokes.count }
        return macro.strokes.reduce(0) { $0 + $1.modifiers.count + ($1.isModifiersOnly ? 0 : 1) }
    }

    public func fits(_ macro: KeyMacro) -> Bool {
        macro.isWellFormed && presses(in: macro) <= pressLimit
    }

    /// Whether the keyboard is given `key`, a usage on the HID keyboard page — the keys its vendor tool
    /// offers. The Windows tool for the 8890 has 95: A (0x04) to Keypad . (0x63) and Menu (0x65), without
    /// the two non-US keys (0x32, 0x64) or Keypad Enter (0x58). The cross-platform app has every usage
    /// from 0x04 to 0x65, and F13–F24 (0x68–0x73).
    public func takes(key: UInt8) -> Bool {
        switch commands {
        case .packets: (0x04...0x63).contains(key) && key != 0x32 && key != 0x58 || key == 0x65
        case .records: (0x04...0x65).contains(key) || (0x68...0x73).contains(key)
        }
    }

    /// Whether the keyboard is given every key `macro` presses.
    public func takesKeys(of macro: KeyMacro) -> Bool {
        macro.strokes.allSatisfy { $0.isModifiersOnly || takes(key: $0.key) }
    }

    public var delays: DelaySupport {
        switch commands {
        case .records(.standard): .perPress(0...60000)
        case .records(.legacy): .perKey(0...6000)
        case .packets, .records(.unidentified): .unavailable
        }
    }

    public var mediaKeys: [MediaKey] {
        switch commands {
        // Report ID 3 takes any consumer usage, but the Windows tool offers its six on every report ID.
        case .packets: MediaKey.basic
        case .records: MediaKey.all
        }
    }

    public var lighting: LightingSupport {
        switch commands {
        case .packets: .modes(LightingSupport.k8890Modes)
        case .records(.standard): .perKeyColor(modes: 0...5, keys: LightingSupport.colorKeyCount)
        case .records(.legacy), .records(.unidentified): .colorAndMode(modes: 0...5)
        }
    }

    public var reading: ReadSupport {
        switch commands {
        case .records(.standard), .records(.legacy): .onConnect
        case .packets, .records(.unidentified): .never
        }
    }

    /// Keyboards no vendor tool draws are arranged by the user within these (`GridShape`); nil for keyboards
    /// that take the cross-platform app's layouts.
    public var gridLimits: GridLimits? {
        if case .packets = commands { return .k8890 }
        return nil
    }

    /// Whether the keyboard can take `control`. The 1189:8890 has twelve keys and two knobs that turn and
    /// press; a 884x keyboard stores every control of its layout.
    public func canAddress(_ control: ControlID) -> Bool {
        guard case .packets = commands else { return true }
        return switch control {
        case .key(let number): (1...12).contains(number)
        case .knob(let number, let part): (1...2).contains(number) && part <= .rotateRight
        }
    }

    public func addresses(_ layout: KeyboardLayout) -> Bool {
        layout.controls.allSatisfy(canAddress)
    }
}

/// How a keyboard keeps waits.
public enum DelaySupport: Hashable, Sendable {
    /// No waits.
    case unavailable
    /// A wait before each press, in milliseconds.
    case perPress(ClosedRange<Int>)
    /// One wait for the whole key, in milliseconds.
    case perKey(ClosedRange<Int>)
}

/// Whether the keyboard tells what it holds.
public enum ReadSupport: Hashable, Sendable {
    case never
    /// Asked as soon as it is connected, as the cross-platform app does, and whenever the user asks.
    case onConnect
}
