/// What came of an edit of the app's copy of the configuration.
public enum EditOutcome: Hashable, Sendable {
    case applied
    /// No key or knob is selected.
    case needsSelection
    /// The keyboard has nothing for this, so nothing changed.
    case unsupported
    /// The key holds no more presses; the value is how many it holds.
    case full(Int)
    /// Modifiers alone make a key a modifier key, so they can't follow or precede other presses.
    case modifiersOnlyAlone
    /// Colours are kept for the first keys only; the value is how many.
    case needsColorKey(Int)
}

/// Where an edit applies: the selected control on the shown layer of a keyboard with these capabilities.
public struct EditTarget: Sendable {
    public let capabilities: KeyboardCapabilities
    public let layer: Int
    public let control: ControlID?

    public init(capabilities: KeyboardCapabilities, layer: Int, control: ControlID?) {
        self.capabilities = capabilities
        self.layer = layer
        self.control = control
    }
}

/// Adds a press to the selected key. A key that did something else starts over with it; a key that holds
/// modifiers alone takes them into the press.
public struct AppendStrokeUseCase: Sendable {
    public init() {}

    public func execute(_ stroke: KeyStroke, in configuration: inout KeyboardConfiguration, at target: EditTarget) -> EditOutcome {
        guard let control = target.control else { return .needsSelection }
        guard stroke.isModifiersOnly || target.capabilities.takes(key: stroke.key) else { return .unsupported }
        var macro = KeyMacro()
        if case .keys(let current) = configuration.action(control, layer: target.layer) { macro = current }
        var stroke = stroke
        if macro.strokes.count == 1, macro.strokes[0].isModifiersOnly {
            stroke.modifiers.formUnion(macro.strokes[0].modifiers)
            stroke.delay = macro.strokes[0].delay
            macro.strokes = []
        }
        macro.strokes.append(stroke)
        guard macro.isWellFormed else { return .modifiersOnlyAlone }
        guard target.capabilities.fits(macro) else { return .full(target.capabilities.pressLimit) }
        configuration.set(.keys(macro), for: control, layer: target.layer)
        return .applied
    }
}

/// Takes the last press off the selected key; the key is cleared when none is left.
public struct RemoveLastStrokeUseCase: Sendable {
    public init() {}

    public func execute(in configuration: inout KeyboardConfiguration, at target: EditTarget) -> EditOutcome {
        guard let control = target.control else { return .needsSelection }
        guard case .keys(var macro) = configuration.action(control, layer: target.layer), !macro.strokes.isEmpty else {
            return .unsupported
        }
        macro.strokes.removeLast()
        configuration.set(macro.strokes.isEmpty && macro.delay == 0 ? .unassigned : .keys(macro), for: control, layer: target.layer)
        return .applied
    }
}

/// Replaces the selected key's action with a media key or a mouse action.
public struct SetActionUseCase: Sendable {
    public init() {}

    public func execute(_ action: KeyAction, in configuration: inout KeyboardConfiguration, at target: EditTarget) -> EditOutcome {
        guard let control = target.control else { return .needsSelection }
        switch action {
        case .media(let key):
            guard target.capabilities.mediaKeys.contains(key) else { return .unsupported }
        case .keys(let macro):
            guard target.capabilities.takesKeys(of: macro) else { return .unsupported }
            guard macro.isWellFormed else { return .modifiersOnlyAlone }
            guard target.capabilities.fits(macro) else { return .full(target.capabilities.pressLimit) }
        case .unassigned, .mouse:
            break
        }
        configuration.set(action, for: control, layer: target.layer)
        return .applied
    }
}

/// Sets the wait before one press of the selected key (standard format).
public struct SetPressDelayUseCase: Sendable {
    public init() {}

    public func execute(press index: Int, milliseconds: Int, in configuration: inout KeyboardConfiguration, at target: EditTarget) -> EditOutcome {
        guard case .perPress(let range) = target.capabilities.delays else { return .unsupported }
        guard let control = target.control else { return .needsSelection }
        guard case .keys(var macro) = configuration.action(control, layer: target.layer),
              macro.strokes.indices.contains(index) else { return .unsupported }
        macro.strokes[index].delay = min(max(milliseconds, range.lowerBound), range.upperBound)
        configuration.set(.keys(macro), for: control, layer: target.layer)
        return .applied
    }
}

/// Sets the one wait the selected key keeps (legacy format). Its presses stay; a key that held a media
/// key or a mouse action has none to keep.
public struct SetKeyDelayUseCase: Sendable {
    public init() {}

    public func execute(milliseconds: Int, in configuration: inout KeyboardConfiguration, at target: EditTarget) -> EditOutcome {
        guard case .perKey(let range) = target.capabilities.delays else { return .unsupported }
        guard let control = target.control else { return .needsSelection }
        var macro = KeyMacro()
        switch configuration.action(control, layer: target.layer) {
        case .keys(let current): macro = current
        case .media, .mouse: return .unsupported
        case .unassigned, nil: break
        }
        macro.delay = min(max(milliseconds, range.lowerBound), range.upperBound)
        configuration.set(macro.strokes.isEmpty && macro.delay == 0 ? .unassigned : .keys(macro), for: control, layer: target.layer)
        return .applied
    }
}

/// Clears the selected key, or every control of the layout on the shown layer.
public struct ClearUseCase: Sendable {
    public init() {}

    public func execute(in configuration: inout KeyboardConfiguration, at target: EditTarget) -> EditOutcome {
        guard let control = target.control else { return .needsSelection }
        configuration.set(.unassigned, for: control, layer: target.layer)
        return .applied
    }

    public func executeAll(_ layout: KeyboardLayout, in configuration: inout KeyboardConfiguration, layer: Int) -> EditOutcome {
        for control in layout.controls {
            configuration.set(.unassigned, for: control, layer: layer)
        }
        return .applied
    }
}

/// Sets the shown layer's lights.
public struct SetLightingUseCase: Sendable {
    public init() {}

    /// The 8890's mode, or the mode of a layer of the other formats — keeping its colours.
    public func execute(mode: UInt8, in configuration: inout KeyboardConfiguration, at target: EditTarget) -> EditOutcome {
        let lighting: LayerLighting
        switch (target.capabilities.lighting, configuration.lighting(layer: target.layer)) {
        case (.modes(let modes), _):
            guard modes.contains(mode) else { return .unsupported }
            lighting = .mode(mode)
        case (.colorAndMode(let modes), let current):
            guard modes.contains(mode) else { return .unsupported }
            var color = LightColor.cyan
            if case .colorMode(let kept, _) = current { color = kept }
            lighting = .colorMode(color: color, mode: mode)
        case (.perKeyColor(let modes, _), let current):
            guard modes.contains(mode) else { return .unsupported }
            var colors = KeyColor.defaultKeyColors
            if case .perKey(_, let kept) = current { colors = kept }
            lighting = .perKey(mode: mode, colors: colors)
        }
        configuration.setLighting(lighting, layer: target.layer)
        return .applied
    }

    /// The colour of a layer that takes one (legacy format and unidentified keyboards).
    public func execute(color: LightColor, in configuration: inout KeyboardConfiguration, at target: EditTarget) -> EditOutcome {
        guard case .colorAndMode(let modes) = target.capabilities.lighting else { return .unsupported }
        var mode = modes.lowerBound
        if case .colorMode(_, let kept) = configuration.lighting(layer: target.layer) { mode = kept }
        configuration.setLighting(.colorMode(color: color, mode: mode), layer: target.layer)
        return .applied
    }

    /// The colour of the selected key (standard format), which must be one of the first keys.
    public func execute(keyColor: KeyColor, in configuration: inout KeyboardConfiguration, at target: EditTarget) -> EditOutcome {
        guard case .perKeyColor(let modes, let keys) = target.capabilities.lighting else { return .unsupported }
        guard let control = target.control else { return .needsSelection }
        guard let index = Self.colorIndex(of: control, keys: keys) else { return .needsColorKey(keys) }
        var mode = modes.lowerBound
        var colors = KeyColor.defaultKeyColors
        if case .perKey(let keptMode, let kept) = configuration.lighting(layer: target.layer) {
            mode = keptMode
            colors = kept
        }
        colors[index] = keyColor
        configuration.setLighting(.perKey(mode: mode, colors: colors), layer: target.layer)
        return .applied
    }

    /// Where a key's colour is kept: keys 1–16 have colours 1–16. (The app colours records 1–16, and a key is
    /// stored in the record of its number.)
    public static func colorIndex(of control: ControlID, keys: Int) -> Int? {
        guard case .key(let number) = control, (1...keys).contains(number) else { return nil }
        return number - 1
    }
}
