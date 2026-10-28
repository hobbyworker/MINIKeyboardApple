/// What the app holds for a keyboard: each layer's actions and lights, and what changed since they were
/// read or saved. What the app doesn't know — a keyboard that can't be read, a key nobody has set — is
/// missing rather than guessed, and is never written.
public struct KeyboardConfiguration: Hashable, Sendable {
    public struct Layer: Hashable, Sendable {
        public fileprivate(set) var actions: [ControlID: KeyAction] = [:]
        public fileprivate(set) var lighting: LayerLighting?
        public fileprivate(set) var changedControls: Set<ControlID> = []
        public fileprivate(set) var lightingChanged = false
    }

    public private(set) var layers: [Layer]

    public init(layerCount: Int) {
        layers = Array(repeating: Layer(), count: max(layerCount, 1))
    }

    public var layerCount: Int { layers.count }

    /// The action of `control`, or nil when the app doesn't know it.
    public func action(_ control: ControlID, layer: Int) -> KeyAction? {
        layers[layer].actions[control]
    }

    public func lighting(layer: Int) -> LayerLighting? {
        layers[layer].lighting
    }

    public func isChanged(_ control: ControlID, layer: Int) -> Bool {
        layers[layer].changedControls.contains(control)
    }

    public var hasUnsavedChanges: Bool {
        layers.contains { !$0.changedControls.isEmpty || $0.lightingChanged }
    }

    /// Sets an action to be written on the next save.
    public mutating func set(_ action: KeyAction, for control: ControlID, layer: Int) {
        layers[layer].actions[control] = action
        layers[layer].changedControls.insert(control)
    }

    /// Sets a layer's lights to be written on the next save.
    public mutating func setLighting(_ lighting: LayerLighting, layer: Int) {
        layers[layer].lighting = lighting
        layers[layer].lightingChanged = true
    }

    /// What the keyboard said it holds. It replaces the app's values, saved or not, as the vendor app
    /// does when it reads.
    public mutating func applyRead(_ actions: [ControlID: KeyAction], layer: Int) {
        for (control, action) in actions {
            layers[layer].actions[control] = action
            layers[layer].changedControls.remove(control)
        }
    }

    public mutating func applyRead(lighting: LayerLighting, layer: Int) {
        layers[layer].lighting = lighting
        layers[layer].lightingChanged = false
    }

    /// Everything was written.
    public mutating func markSaved() {
        markSaved(except: [:], lighting: [])
    }

    /// Everything was written, but these controls (by layer) and these layers' lights read back otherwise: they
    /// stay changed, with the values the user gave them.
    public mutating func markSaved(except controls: [Int: Set<ControlID>], lighting: Set<Int>) {
        for index in layers.indices {
            layers[index].changedControls.formIntersection(controls[index] ?? [])
            layers[index].lightingChanged = layers[index].lightingChanged && lighting.contains(index)
        }
    }
}

/// What reading one layer brought back: the actions that came, and the controls the read asked for that didn't —
/// their answer never came, or came in a kind the app doesn't know.
public struct LayerRead: Hashable, Sendable {
    public var actions: [ControlID: KeyAction]
    public var unread: Set<ControlID>
    /// The layout's controls in records beyond those the read asks for: neither read nor unread.
    public var outside: Set<ControlID>

    public init(actions: [ControlID: KeyAction], unread: Set<ControlID> = [], outside: Set<ControlID> = []) {
        self.actions = actions
        self.unread = unread
        self.outside = outside
    }
}
