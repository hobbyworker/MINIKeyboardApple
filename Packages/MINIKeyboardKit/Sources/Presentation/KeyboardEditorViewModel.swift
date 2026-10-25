import Foundation
import Observation
import Domain

/// The main window's state and what the user does in it: the keyboard connected, its layout, the layer, key
/// and page shown, and the app's copy of the keyboard's configuration. The rules are the use cases'; this
/// keeps the screen, turns their outcomes into notices, and gives the views what they draw in the
/// presentation's own types (`KeyboardEditorViewModel+Screen`).
@MainActor
@Observable
public final class KeyboardEditorViewModel {
    public private(set) var activity: Activity?
    public private(set) var notice: Notice?
    /// The layout sheet is up — on its own when a keyboard that can't say its shape needs one set.
    public var isChoosingLayout = false
    public var tab: EditorTab = .keys
    public var layer = 0

    private(set) var connection: ConnectionState = .searching
    private(set) var identification: KeyboardIdentification?
    private(set) var resolvedLayout: ResolvedLayout?
    private(set) var configuration = KeyboardConfiguration(layerCount: 3)
    private(set) var selection: ControlID?
    /// Modifiers picked for the next key.
    private(set) var held: Modifiers = []
    /// The keyboard on USB, or a simulated one.
    private(set) var source: KeyboardSource = .hardware

    @ObservationIgnored private let observeConnection: ObserveConnectionUseCase
    @ObservationIgnored private let retryConnectionUseCase: RetryConnectionUseCase
    @ObservationIgnored private let identifyKeyboard: IdentifyKeyboardUseCase
    @ObservationIgnored private let resolveLayout: ResolveLayoutUseCase
    @ObservationIgnored private let chooseLayoutUseCase: ChooseLayoutUseCase
    @ObservationIgnored private let readKeyboard: ReadKeyboardUseCase
    @ObservationIgnored private let saveKeyboard: SaveKeyboardUseCase
    @ObservationIgnored private let keyboardSource: KeyboardSourceUseCase?
    @ObservationIgnored private let appendStroke = AppendStrokeUseCase()
    @ObservationIgnored private let removeLastStrokeUseCase = RemoveLastStrokeUseCase()
    @ObservationIgnored private let setAction = SetActionUseCase()
    @ObservationIgnored private let setPressDelay = SetPressDelayUseCase()
    @ObservationIgnored private let setKeyDelayUseCase = SetKeyDelayUseCase()
    @ObservationIgnored private let clear = ClearUseCase()
    @ObservationIgnored private let setLighting = SetLightingUseCase()
    @ObservationIgnored private var connectionTask: Task<Void, Never>?
    @ObservationIgnored private var noticeTask: Task<Void, Never>?

    public init(
        observeConnection: ObserveConnectionUseCase, retryConnection: RetryConnectionUseCase,
        identifyKeyboard: IdentifyKeyboardUseCase, resolveLayout: ResolveLayoutUseCase,
        chooseLayout: ChooseLayoutUseCase, readKeyboard: ReadKeyboardUseCase, saveKeyboard: SaveKeyboardUseCase,
        keyboardSource: KeyboardSourceUseCase? = nil
    ) {
        self.observeConnection = observeConnection
        retryConnectionUseCase = retryConnection
        self.identifyKeyboard = identifyKeyboard
        self.resolveLayout = resolveLayout
        chooseLayoutUseCase = chooseLayout
        self.readKeyboard = readKeyboard
        self.saveKeyboard = saveKeyboard
        self.keyboardSource = keyboardSource
    }

    /// Follows the keyboard; one that comes is identified at once.
    public func start() {
        guard connectionTask == nil else { return }
        let observeConnection = observeConnection
        let keyboardSource = keyboardSource
        connectionTask = Task { [weak self] in
            if let keyboardSource {
                let source = await keyboardSource.current()
                self?.source = source
            }
            for await state in await observeConnection.execute() {
                guard let self else { return }
                await self.connectionChanged(state)
            }
        }
    }

    // MARK: - State the rules work on

    var keyboard: ConnectedKeyboard? { connection.keyboard }

    var capabilities: KeyboardCapabilities? {
        identification.map { KeyboardCapabilities(commands: $0.commands) }
    }

    /// Connected, identified and not busy.
    public var isReady: Bool { keyboard != nil && identification != nil && activity == nil }

    public var layerCount: Int { capabilities?.layerCount ?? 3 }

    public var availableTabs: [EditorTab] {
        guard let capabilities else { return EditorTab.allCases }
        return EditorTab.allCases.filter { $0 != .delay || capabilities.delays != .unavailable }
    }

    /// Whether the keyboard reads back at all — then the header has Read.
    public var readsBack: Bool { (capabilities?.reading ?? .never) != .never }

    public var canRead: Bool { isReady && readsBack }

    public var hasUnsavedChanges: Bool { configuration.hasUnsavedChanges }

    func action(for control: ControlID) -> KeyAction? {
        configuration.action(control, layer: layer)
    }

    var selectedAction: KeyAction? { selection.flatMap(action) }

    var lighting: LayerLighting? { configuration.lighting(layer: layer) }

    /// The colour of a key on a keyboard that lights each key.
    func keyColor(for control: ControlID) -> KeyColor? {
        guard case .perKeyColor(_, let keys)? = capabilities?.lighting, case .perKey(_, let colors)? = lighting,
              let index = SetLightingUseCase.colorIndex(of: control, keys: keys)
        else { return nil }
        return colors[index]
    }

    // MARK: - Connection

    private func connectionChanged(_ state: ConnectionState) async {
        let previous = connection.keyboard
        connection = state
        guard state.keyboard != previous else { return }
        identification = nil
        selection = nil
        held = []
        if let keyboard = state.keyboard {
            if keyboard.usb != previous?.usb { resolvedLayout = nil }
            await identify()
        }
    }

    public func retryConnection() async {
        await retryConnectionUseCase.execute()
    }

    /// Settles the keyboard's commands and layout, then reads it if it reads back on its own.
    public func identify() async {
        guard let keyboard, identification == nil, activity == nil else { return }
        activity = .identifying
        let identified: KeyboardIdentification
        do {
            identified = try await identifyKeyboard.execute(keyboard)
        } catch {
            activity = nil
            show(.identifyFailed)
            return
        }
        activity = nil
        guard connection.keyboard == keyboard else { return }
        identification = identified
        let capabilities = KeyboardCapabilities(commands: identified.commands)
        let resolved = resolveLayout.execute(keyboard, identification: identified)
        resolvedLayout = resolved
        configuration = KeyboardConfiguration(layerCount: capabilities.layerCount)
        layer = min(layer, capabilities.layerCount - 1)
        if !availableTabs.contains(tab) { tab = .keys }
        isChoosingLayout = resolved.needsChoice
        if capabilities.reading == .onConnect {
            await read(announce: false)
        }
    }

    // MARK: - Reading and saving

    public func read(announce: Bool = true) async {
        guard canRead, let capabilities, let layout = resolvedLayout?.layout else { return }
        activity = .reading
        let outcome = await readKeyboard.execute(configuration, capabilities: capabilities, layout: layout)
        activity = nil
        configuration = outcome.configuration
        if outcome.error != nil {
            show(.readFailed)
        } else if announce {
            show(.readComplete)
        }
    }

    public func save() async {
        guard isReady, let capabilities, let layout = resolvedLayout?.layout else { return }
        guard configuration.hasUnsavedChanges else {
            show(.nothingToSave)
            return
        }
        activity = .saving
        defer { activity = nil }
        do {
            switch try await saveKeyboard.execute(configuration, capabilities: capabilities, layout: layout) {
            case .saved(let saved):
                configuration = saved
                show(.saved(simulated: activeSimulatorID != nil))
            case .nothingToSave:
                show(.nothingToSave)
            }
        } catch {
            switch error {
            case .writeFailed(let code): show(.writeFailed(code))
            case .unsupported: show(.unsupported)
            default: show(.keyboardGone)
            }
        }
    }

    // MARK: - Layout

    /// The layout and rotation the user chose; on a keyboard that said its shape, only the rotation.
    func chooseLayout(_ layout: KeyboardLayout, rotation: Rotation) {
        guard let keyboard, let resolved = resolvedLayout else { return }
        resolvedLayout = chooseLayoutUseCase.execute(resolved, layout: layout, rotation: rotation, for: keyboard.usb)
        isChoosingLayout = false
        if let selection, resolvedLayout?.layout.controls.contains(selection) == false { self.selection = nil }
    }

    /// One of the cross-platform app's layouts by its name, or with nil the keyboard's own — only turned.
    public func chooseLayout(_ id: String?, quarterTurns: Int) {
        guard let layout = id.flatMap(KeyboardLayout.named) ?? resolvedLayout?.layout else { return }
        chooseLayout(layout, rotation: Self.rotation(quarterTurns))
    }

    /// An arrangement: keys, keys to a row, knobs.
    public func chooseArrangement(keys: Int, columns: Int, knobs: Int, quarterTurns: Int) {
        guard let shape = GridShape(keys: keys, columns: columns, knobs: knobs) else { return }
        chooseLayout(shape.layout, rotation: Self.rotation(quarterTurns))
    }

    /// Whether there is a layout to turn or change.
    public var hasLayout: Bool { resolvedLayout != nil }

    public func rotate() {
        guard let resolved = resolvedLayout else { return }
        chooseLayout(resolved.layout, rotation: resolved.rotation.next)
    }

    static func rotation(_ quarterTurns: Int) -> Rotation {
        Rotation(rawValue: ((quarterTurns % 4) + 4) % 4) ?? .upright
    }

    // MARK: - Editing

    public func select(_ control: ControlRef) {
        guard isReady else { return }
        selection = control.id
    }

    private var target: EditTarget? {
        capabilities.map { EditTarget(capabilities: $0, layer: layer, control: selection) }
    }

    private func edit(_ change: (inout KeyboardConfiguration, EditTarget) -> EditOutcome) {
        guard isReady, let target else { return }
        report(change(&configuration, target))
    }

    /// A key, with the modifiers held for it.
    public func press(_ key: KeyUsage) {
        let stroke = KeyStroke(modifiers: held, key: key.usage)
        edit { appendStroke.execute(stroke, in: &$0, at: $1) }
        held = []
    }

    /// A shifted symbol: Shift and its key.
    public func press(shifted key: KeyUsage) {
        let stroke = KeyStroke(modifiers: held.union(.shift), key: key.usage)
        edit { appendStroke.execute(stroke, in: &$0, at: $1) }
        held = []
    }

    public func toggle(_ modifier: ModifierKey) {
        held.formSymmetricDifference(modifier.modifiers)
    }

    /// The held modifiers alone, which makes the key a modifier key.
    public func assignHeldModifiers() {
        guard !held.isEmpty else { return }
        let stroke = KeyStroke(modifiers: held, key: 0)
        edit { appendStroke.execute(stroke, in: &$0, at: $1) }
        held = []
    }

    public func removeLastStroke() {
        edit { removeLastStrokeUseCase.execute(in: &$0, at: $1) }
    }

    public func assign(_ media: MediaChoice) {
        edit { setAction.execute(.media(media.key), in: &$0, at: $1) }
    }

    public func assign(_ mouse: MouseChoice) {
        edit { setAction.execute(.mouse(mouse.action), in: &$0, at: $1) }
    }

    public func setDelay(press index: Int, milliseconds: Int) {
        edit { setPressDelay.execute(press: index, milliseconds: milliseconds, in: &$0, at: $1) }
    }

    public func setKeyDelay(milliseconds: Int) {
        edit { setKeyDelayUseCase.execute(milliseconds: milliseconds, in: &$0, at: $1) }
    }

    public func clearSelected() {
        edit { clear.execute(in: &$0, at: $1) }
    }

    public func clearLayer() {
        guard let layout = resolvedLayout?.layout else { return }
        let layer = layer
        edit { configuration, _ in clear.executeAll(layout, in: &configuration, layer: layer) }
    }

    public func setLightingMode(_ mode: Int) {
        edit { setLighting.execute(mode: UInt8(clamping: mode), in: &$0, at: $1) }
    }

    public func setLightColor(_ color: LEDColor) {
        edit { setLighting.execute(color: color.color, in: &$0, at: $1) }
    }

    public func setKeyColor(_ color: RGB) {
        edit { setLighting.execute(keyColor: color.keyColor, in: &$0, at: $1) }
    }

    private func report(_ outcome: EditOutcome) {
        switch outcome {
        case .applied: break
        case .needsSelection: show(.selectControlFirst)
        case .unsupported: show(.unsupported)
        case .full(let limit): show(.full(limit))
        case .modifiersOnlyAlone: show(.modifiersOnlyAlone)
        case .needsColorKey(let keys): show(.needsColorKey(keys))
        }
    }

    // MARK: - Simulator

    public var canSelectSource: Bool { keyboardSource != nil }

    /// Every keyboard the simulator plays, when it is wired in.
    public var simulatorChoices: [SimulatorChoice] {
        keyboardSource == nil ? [] : SimulatedModel.all.map(SimulatorChoice.init)
    }

    /// The simulated keyboard in use, or nil for the keyboard on USB.
    public var activeSimulatorID: String? {
        if case .simulated(let model) = source { return model.id }
        return nil
    }

    /// Switches to a simulated keyboard, or with nil to the keyboard on USB. The switch reports "searching"
    /// first, so the window starts over as after re-plugging.
    public func selectSimulator(_ id: String?) async {
        let new: KeyboardSource
        if let id {
            guard let model = SimulatedModel.all.first(where: { $0.id == id }) else { return }
            new = .simulated(model)
        } else {
            new = .hardware
        }
        guard let keyboardSource, new != source else { return }
        await keyboardSource.select(new)
        source = new
    }

    // MARK: - Notices

    public func dismissNotice() {
        noticeTask?.cancel()
        notice = nil
    }

    private func show(_ notice: Notice) {
        self.notice = notice
        noticeTask?.cancel()
        noticeTask = Task { [weak self] in
            try? await Task.sleep(for: notice.lifetime)
            guard !Task.isCancelled else { return }
            self?.notice = nil
        }
    }
}

/// The device log window.
@MainActor
@Observable
public final class DeviceLogViewModel {
    public struct Line: Hashable, Sendable, Identifiable {
        public enum Direction: Hashable, Sendable { case output, input, event }

        /// What happened to the connection; the window names it.
        public enum Event: Hashable, Sendable {
            case searching
            case connected(usb: String, interface: Int)
            case needsPermission
            case openFailed(code: Int32)
            case writeFailed(code: Int32)
            case simulated(id: String)
        }

        public let id: UUID
        public let date: Date
        public let direction: Direction
        /// Every byte of the report written or read; empty for an event.
        public let bytes: [UInt8]
        public let event: Event?

        /// The report up to the zero padding at its end: "03 FB FB FB".
        public var summary: String { PacketText.summary(bytes) }

        /// Whether `summary` leaves bytes out.
        public var isShortened: Bool { PacketText.summaryCount(bytes) < bytes.count }

        /// Every byte, 16 to a row after the row's offset: "0010  00 00 00 …".
        public var rows: [String] { PacketText.rows(bytes) }

        /// Every byte on one line.
        public var hex: String { PacketText.hex(bytes[...]) }
    }

    public private(set) var entries: [Line] = []

    @ObservationIgnored private let log: DeviceLogUseCase
    @ObservationIgnored private var observation: Task<Void, Never>?

    public init(log: DeviceLogUseCase) {
        self.log = log
    }

    public func start() {
        guard observation == nil else { return }
        let log = log
        observation = Task { [weak self] in
            for await entries in await log.entries() {
                guard let self else { return }
                self.entries = entries.map(Self.line)
            }
        }
    }

    public func clear() {
        let log = log
        Task { await log.clear() }
    }

    private static func line(_ entry: DeviceLogEntry) -> Line {
        switch entry.content {
        case .output(let bytes):
            return Line(id: entry.id, date: entry.date, direction: .output, bytes: bytes, event: nil)
        case .input(let bytes):
            return Line(id: entry.id, date: entry.date, direction: .input, bytes: bytes, event: nil)
        case .event(let event):
            let shown: Line.Event = switch event {
            case .searching: .searching
            case .connected(let usb, let interface): .connected(usb: usb.description, interface: interface)
            case .needsPermission: .needsPermission
            case .openFailed(let code): .openFailed(code: code)
            case .writeFailed(let code): .writeFailed(code: code)
            case .simulated(let id): .simulated(id: id)
            }
            return Line(id: entry.id, date: entry.date, direction: .event, bytes: [], event: shown)
        }
    }
}
