/// The layout to draw for a newly identified keyboard. A keyboard that said how many keys and knobs it has
/// gets the layout the cross-platform app draws for that — its records follow it, so it is not the user's
/// to change, only how it is turned. A 884x keyboard that doesn't say gets the layout the user chose from
/// the app's, and the 1189:8890 — which that app doesn't know, and whose own tool draws no shape — the
/// arrangement the user gave it (`GridShape`). Until they choose: what the vendor tool would show.
public struct ResolveLayoutUseCase: Sendable {
    private let profiles: any LayoutProfileRepository

    public init(profiles: any LayoutProfileRepository) {
        self.profiles = profiles
    }

    public func execute(_ keyboard: ConnectedKeyboard, identification: KeyboardIdentification) -> ResolvedLayout {
        let saved = profiles.profile(for: keyboard.usb)
        let rotation = saved?.rotation ?? .upright
        if let identity = identification.identity {
            let id = KeyboardLayout.identifiedID(for: identity, productID: keyboard.usb.productID)
            if let layout = KeyboardLayout.named(id) {
                return ResolvedLayout(layout: layout, rotation: rotation, source: .identified, choices: [])
            }
        }
        let capabilities = KeyboardCapabilities(commands: identification.commands)
        if let grid = capabilities.gridLimits {
            if let saved, let shape = GridShape(id: saved.layoutID), grid.contains(shape) {
                return ResolvedLayout(layout: shape.layout, rotation: saved.rotation, source: .chosen, choices: [], grid: grid)
            }
            return ResolvedLayout(layout: grid.assumed.layout, rotation: rotation, source: .assumed, choices: [], grid: grid)
        }
        let choices = Self.choices(for: capabilities)
        if let saved, let layout = choices.first(where: { $0.id == saved.layoutID }) {
            return ResolvedLayout(layout: layout, rotation: saved.rotation, source: .chosen, choices: choices)
        }
        return ResolvedLayout(layout: Self.assumed(in: choices), rotation: rotation, source: .assumed, choices: choices)
    }

    /// Every layout the keyboard can address, fewest controls first.
    public static func choices(for capabilities: KeyboardCapabilities) -> [KeyboardLayout] {
        KeyboardLayout.all.filter(capabilities.addresses)
            .sorted { ($0.keyCount, $0.knobCount, $0.id) < ($1.keyCount, $1.knobCount, $1.id) }
    }

    /// What each vendor tool draws for a keyboard it knows nothing of: the cross-platform app's 15 keys and
    /// three knobs, or where the keyboard can't have that, the layout with the most controls — the Windows
    /// tool's 12 keys and two knobs.
    static func assumed(in choices: [KeyboardLayout]) -> KeyboardLayout {
        choices.first { $0.id == KeyboardLayout.fallbackID }
            ?? choices.max { ($0.controls.count, $1.id) < ($1.controls.count, $0.id) }
            ?? KeyboardLayout.named(KeyboardLayout.fallbackID)!
    }
}

/// Keeps the user's choice of layout and rotation for a keyboard.
public struct ChooseLayoutUseCase: Sendable {
    private let profiles: any LayoutProfileRepository

    public init(profiles: any LayoutProfileRepository) {
        self.profiles = profiles
    }

    /// The resolved layout with `layout` and `rotation` in place. The layout of a keyboard that said its
    /// shape stays as it is; only the rotation is kept.
    public func execute(
        _ resolved: ResolvedLayout, layout: KeyboardLayout, rotation: Rotation, for keyboard: USBIdentity
    ) -> ResolvedLayout {
        let allowed = if let grid = resolved.grid {
            GridShape(id: layout.id).map(grid.contains) ?? false
        } else {
            resolved.choices.contains(layout)
        }
        let chosen = resolved.source == .identified || !allowed ? resolved.layout : layout
        profiles.save(LayoutProfile(layoutID: chosen.id, rotation: rotation), for: keyboard)
        let source: ResolvedLayout.Source = resolved.source == .identified ? .identified : .chosen
        return ResolvedLayout(layout: chosen, rotation: rotation, source: source, choices: resolved.choices, grid: resolved.grid)
    }
}
