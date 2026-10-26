import Domain

// What each part of the window draws, in the presentation's types.
extension KeyboardEditorViewModel {
    // MARK: - Header

    public var status: ConnectionStatus {
        switch connection {
        case .searching: .searching
        case .needsPermission: .needsPermission
        case .openFailed(let code): .openFailed(code: code)
        case .connected(let keyboard):
            .connected(usb: keyboard.usb.description, keys: identification?.identity?.keyCount,
                       knobs: identification?.identity?.knobCount, isIdentified: identification != nil,
                       isSimulated: source.isSimulated)
        }
    }

    public var keyboardInfo: KeyboardInfo? {
        keyboard.map { KeyboardInfo(keyboard: $0, identification: identification) }
    }

    // MARK: - The keyboard

    public var drawing: KeyboardDrawing? {
        guard let resolved = resolvedLayout,
              let geometry = LayoutGeometry.of(resolved.layout)?.rotated(resolved.rotation)
        else { return nil }
        let controls = resolved.layout.controls.compactMap { control -> ControlDrawing? in
            guard let rect = geometry.rects[control] else { return nil }
            let face: ControlDrawing.Face = switch control {
            case .key(let number): .key(number)
            case .knob(_, let part): .knob(KnobAction(part))
            }
            return ControlDrawing(
                ref: ControlRef(control), face: face, rect: rect, caption: ActionCaption(action(for: control)),
                isSelected: selection == control, isChanged: configuration.isChanged(control, layer: layer),
                ledColor: tab == .lighting ? keyColor(for: control).map(RGB.init) : nil)
        }
        return KeyboardDrawing(frame: geometry.frame, bounds: geometry.bounds, controls: controls)
    }

    // MARK: - Selection

    public var selectedControl: ControlRef? { selection.map(ControlRef.init) }

    public var selectionState: SelectionState? {
        guard let selection else { return nil }
        let binding: BindingState = switch action(for: selection) {
        case nil: .unknown
        case .unassigned?: .nothing
        case .keys(let macro)?:
            .presses(strokes: macro.strokes.map(ActionText.stroke), keyDelay: macro.delay,
                     used: capabilities?.presses(in: macro) ?? macro.strokes.count, limit: pressLimit)
        case .media(let key)?: MediaChoice(key).map(BindingState.media) ?? .otherMedia(key.usage)
        case .mouse(let mouse)?: .mouse(MouseChoice(mouse))
        }
        return SelectionState(title: ControlRef(selection).title, layerNumber: layerCount > 1 ? layer + 1 : nil, binding: binding)
    }

    /// What the selected key does, for marking the page's matching button.
    public var selectedCaption: ActionCaption? { selection.map { ActionCaption(action(for: $0)) } }

    // MARK: - Keys page

    public var heldModifiers: Set<ModifierKey> {
        Set(ModifierKey.allCases.filter { held.contains($0.modifiers) })
    }

    /// "⌃⌘", or nil when none is held.
    public var heldModifierText: String? {
        held.isEmpty ? nil : ActionText.modifiers(held)
    }

    public var pressLimit: Int { capabilities?.pressLimit ?? 0 }

    /// Whether each modifier takes a place of its own in a key, as on the standard format.
    public var modifiersCountAsPresses: Bool { capabilities?.modifiersTakePlaces ?? false }

    /// How the keyboard's vendor tool lays out its keys — the Windows tool's groups for the 8890, the
    /// cross-platform app's full-size keyboard for the rest — until the user picks one.
    public var vendorKeyArrangement: KeyArrangement {
        if case .packets? = capabilities?.commands { return .alphabetical }
        return .qwerty
    }

    /// The full-size keyboard. A key the keyboard isn't given keeps its place but is off.
    public var keyBoard: [BoardCap] {
        FullKeyboard.places.map { place in
            let isEnabled = switch place.face {
            case .key(let key): takes(key)
            case .modifier: true
            }
            return BoardCap(face: place.face, row: place.row, column: place.column, width: place.width, isEnabled: isEnabled)
        }
    }

    /// The keys a full-size keyboard doesn't have — F13–F24 and the two non-US keys — that the keyboard is given.
    public var moreKeys: [KeyUsage] {
        (KeyUsage.extraFunctionKeys + KeyUsage.international).filter(takes)
    }

    /// The alphabetical arrangement: groups of the keys the keyboard is given, leaving out empty ones.
    public var keyGroups: [KeyGroup] {
        KeyGroup.Kind.allCases.compactMap { kind in
            let keys = kind.keys.filter(takes)
            return keys.isEmpty ? nil : KeyGroup(kind: kind, keys: keys)
        }
    }

    /// Digits and symbols with their shifted characters, sent as Shift and the key.
    public var shiftSymbols: [KeyUsage] {
        (KeyUsage.digits + KeyUsage.symbols).filter { $0.shifted != nil && takes($0) }
    }

    /// Every key, before a keyboard is identified.
    private func takes(_ key: KeyUsage) -> Bool {
        capabilities?.takes(key: key.usage) ?? true
    }

    // MARK: - Media page

    public var mediaChoices: [MediaChoice] {
        (capabilities?.mediaKeys ?? MediaKey.all).compactMap(MediaChoice.init)
    }

    // MARK: - LED page

    public var lightingPage: LightingPage? {
        guard let support = capabilities?.lighting else { return nil }
        let current = lighting
        switch support {
        case .modes(let modes):
            var active: Int?
            if case .mode(let mode)? = current { active = Int(mode) }
            return .modes(modes.map(Int.init), active: active)
        case .colorAndMode(let modes):
            var color: LEDColor?, mode: Int?
            if case .colorMode(let kept, let keptMode)? = current {
                color = LEDColor(kept)
                mode = Int(keptMode)
            }
            return .colorAndMode(colors: LEDColor.allCases, modes: modes.map(Int.init), activeColor: color, activeMode: mode)
        case .perKeyColor(let modes, let keys):
            let selected = selection.flatMap { control in
                keyColor(for: control).map { KeyColorSelection(title: ControlRef(control).title, color: RGB($0)) }
            }
            return .perKeyColor(modes: modes.map(Int.init), activeMode: current.map { Int($0.mode) }, keys: keys, selected: selected)
        }
    }

    // MARK: - Delay page

    public var delayPage: DelayPage {
        switch capabilities?.delays {
        case .perPress(let range)?:
            guard case .keys(let macro)? = selectedAction else { return .perPress(range: range, presses: []) }
            return .perPress(range: range, presses: macro.strokes.enumerated().map {
                PressDelay(index: $0.offset, text: ActionText.stroke($0.element), delay: $0.element.delay)
            })
        case .perKey(let range)?:
            guard selection != nil else { return .perKey(range: range, value: nil) }
            if case .keys(let macro)? = selectedAction { return .perKey(range: range, value: macro.delay) }
            return .perKey(range: range, value: 0)
        case .unavailable?, nil:
            return .unavailable
        }
    }

    // MARK: - Keyboards on USB

    /// The keyboards plugged in, to choose which is open — only when there is more than one.
    public var keyboardChoices: [KeyboardChoice] {
        let keyboards = attached.keyboards
        guard keyboards.count > 1 else { return [] }
        var seen: [USBIdentity: Int] = [:]
        return keyboards.map { keyboard in
            let sameID = keyboards.filter { $0.usb == keyboard.usb }.count
            seen[keyboard.usb, default: 0] += 1
            let title = sameID > 1 ? "\(keyboard.usb) (\(seen[keyboard.usb] ?? 1))" : keyboard.usb.description
            return KeyboardChoice(id: keyboard.id, title: title, isSelected: keyboard.id == attached.selected)
        }
    }

    // MARK: - Layout sheet

    public var layoutSheet: LayoutSheetState? {
        guard let resolved = resolvedLayout, let keyboard else { return nil }
        let mode: LayoutSheetState.Mode
        if resolved.source == .identified {
            mode = .fixed
        } else if let grid = resolved.grid {
            let shape = GridShape(id: resolved.layout.id) ?? grid.assumed
            mode = .arrangement(keys: shape.keys, columns: shape.columns, knobs: shape.knobs,
                                maxKeys: grid.maxKeys, maxKnobs: grid.maxKnobs)
        } else {
            let choices = resolved.choices.compactMap { layout in
                LayoutGeometry.of(layout).map {
                    LayoutChoice(id: layout.id, keys: layout.keyCount, knobs: layout.knobCount, drawing: ShapeDrawing($0))
                }
            }
            mode = .catalog(choices, selectedID: resolved.layout.id)
        }
        return LayoutSheetState(
            usb: keyboard.usb.description, reportedKeys: identification?.identity?.keyCount,
            reportedKnobs: identification?.identity?.knobCount, mode: mode, quarterTurns: resolved.rotation.rawValue,
            isRequired: resolved.needsChoice)
    }

    /// One of the app's layouts by its name, or with nil the keyboard's own, drawn small and turned.
    public func previewDrawing(layoutID: String?, quarterTurns: Int) -> ShapeDrawing? {
        guard let layout = layoutID.flatMap(KeyboardLayout.named) ?? resolvedLayout?.layout,
              let geometry = LayoutGeometry.of(layout)
        else { return nil }
        return ShapeDrawing(geometry.rotated(Self.rotation(quarterTurns)))
    }

    /// An arrangement drawn small and turned; nil when it is not one a keyboard can have.
    public func previewDrawing(keys: Int, columns: Int, knobs: Int, quarterTurns: Int) -> ShapeDrawing? {
        guard let shape = GridShape(keys: keys, columns: columns, knobs: knobs) else { return nil }
        return ShapeDrawing(LayoutGeometry(arrangement: shape).rotated(Self.rotation(quarterTurns)))
    }
}
