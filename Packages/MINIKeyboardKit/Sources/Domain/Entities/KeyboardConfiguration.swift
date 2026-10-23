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
        for index in layers.indices {
            layers[index].changedControls = []
            layers[index].lightingChanged = false
        }
    }
}
