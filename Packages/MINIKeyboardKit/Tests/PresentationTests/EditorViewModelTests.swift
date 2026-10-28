import Testing
@testable import Presentation
import Domain

/// A keyboard that is plugged in when asked, and the switch to the simulator.
final class FakeConnection: KeyboardConnectionRepository, KeyboardSourceRepository, @unchecked Sendable {
    let continuation: AsyncStream<ConnectionState>.Continuation
    let stream: AsyncStream<ConnectionState>

    init() {
        (stream, continuation) = AsyncStream.makeStream(of: ConnectionState.self)
        continuation.yield(.searching)
    }

    func connectionStates() async -> AsyncStream<ConnectionState> { stream }
    func retry() async {}

    /// The keyboards plugged in, sent when a test says so.
    let attached = AsyncStream.makeStream(of: AttachedKeyboards.self)
    private(set) var selected: [AttachedKeyboard.ID] = []

    func attachedKeyboards() async -> AsyncStream<AttachedKeyboards> { attached.stream }
    func selectKeyboard(_ id: AttachedKeyboard.ID) async { selected.append(id) }

    /// The keyboard on USB until a test switches; the switches, in order.
    private(set) var sources: [KeyboardSource] = []

    func current() async -> KeyboardSource { .hardware }
    func select(_ source: KeyboardSource) async { sources.append(source) }
}

/// The open keyboard, whichever it is. It keeps what is written to it — as `keeps` turns it. The calls in `holds` wait
/// until the test lets them go, so it can change the connection in the middle of one.
@MainActor
final class FakeDevice: KeyboardDeviceRepository {
    enum Call { case identity, read, write }

    var identity: KeyboardIdentity?
    /// What every layer holds, under what was written to it.
    var actions: [ControlID: KeyAction] = [:]
    /// Controls whose answers don't come.
    var unread: Set<ControlID> = []
    var failWrite: KeyboardDeviceError?
    var keeps: (KeyAction) -> KeyAction = { $0 }
    var holds: Set<Call> = []
    private(set) var writes: [KeyboardConfiguration] = []
    private(set) var reads = 0
    private var written: [Int: [ControlID: KeyAction]] = [:]
    private var waiting: [CheckedContinuation<Void, Never>] = []

    /// Whether a call is waiting to be let go.
    var isHolding: Bool { !waiting.isEmpty }

    /// Lets the calls waiting go on, and holds none from now on.
    func letGo() {
        holds = []
        waiting.forEach { $0.resume() }
        waiting = []
    }

    private func wait(_ call: Call) async {
        guard holds.contains(call) else { return }
        await withCheckedContinuation { waiting.append($0) }
    }

    func askIdentity() async throws(KeyboardDeviceError) -> KeyboardIdentity? {
        await wait(.identity)
        return identity
    }

    func readActions(layer: Int, format: RecordFormat, layout: KeyboardLayout) async throws(KeyboardDeviceError) -> LayerRead {
        reads += 1
        await wait(.read)
        let held = actions.merging(written[layer] ?? [:]) { $1 }.filter { !unread.contains($0.key) }
        return LayerRead(actions: held, unread: unread)
    }

    nonisolated func storedForm(of action: KeyAction, format: RecordFormat) -> KeyAction? { action }

    func readLighting(layer: Int) async throws(KeyboardDeviceError) -> LayerLighting {
        .perKey(mode: 0, colors: KeyColor.defaultKeyColors)
    }

    func write(_ configuration: KeyboardConfiguration, commands: CommandSet, layout: KeyboardLayout) async throws(KeyboardDeviceError) {
        await wait(.write)
        if let failWrite { throw failWrite }
        writes.append(configuration)
        for layer in 0..<configuration.layerCount {
            for control in layout.controls where configuration.isChanged(control, layer: layer) {
                written[layer, default: [:]][control] = configuration.action(control, layer: layer).map(keeps)
            }
        }
    }
}

final class Profiles: LayoutProfileRepository, @unchecked Sendable {
    var saved: [USBIdentity: LayoutProfile] = [:]
    func profile(for keyboard: USBIdentity) -> LayoutProfile? { saved[keyboard] }
    func save(_ profile: LayoutProfile, for keyboard: USBIdentity) { saved[keyboard] = profile }
}

@MainActor
struct EditorViewModelTests {
    let connection = FakeConnection()
    let device = FakeDevice()
    let profiles = Profiles()

    static let k8890 = ConnectedKeyboard(
        usb: USBIdentity(vendorID: 0x1189, productID: 0x8890), family: .k8890, interfaceNumber: 1,
        channel: .usb(outEndpoint: 2), reportID: 3, reportLength: 65, details: nil)
    static let k8840 = ConnectedKeyboard(
        usb: USBIdentity(vendorID: 0x1189, productID: 0x8840), family: .k884x, interfaceNumber: 0, channel: .hid,
        reportID: 3, reportLength: 65, details: nil)
    static let c = KeyUsage.named(0x06)!
    static let a = KeyUsage.named(0x04)!
    /// The 8890 and a 884x keyboard, plugged in together.
    static let plugged = AttachedKeyboards(keyboards: [
        AttachedKeyboard(id: "a", usb: k8890.usb, location: "01100000"),
        AttachedKeyboard(id: "b", usb: k8840.usb, location: "02100000"),
    ], selected: "a")
    static let simulated8890 = SimulatedModel.all.first { $0.id == "8890-3" }!

    func editor() -> KeyboardEditorViewModel {
        let editor = KeyboardEditorViewModel(
            observeConnection: ObserveConnectionUseCase(repository: connection),
            retryConnection: RetryConnectionUseCase(repository: connection),
            identifyKeyboard: IdentifyKeyboardUseCase(repository: device, attempts: 1),
            resolveLayout: ResolveLayoutUseCase(profiles: profiles), chooseLayout: ChooseLayoutUseCase(profiles: profiles),
            readKeyboard: ReadKeyboardUseCase(repository: device), saveKeyboard: SaveKeyboardUseCase(repository: device),
            keyboardSource: KeyboardSourceUseCase(repository: connection),
            observeAttachedKeyboards: ObserveAttachedKeyboardsUseCase(repository: connection),
            selectKeyboard: SelectKeyboardUseCase(repository: connection))
        editor.start()
        return editor
    }

    /// Waits for the editor to settle after a connection change.
    func settle(_ editor: KeyboardEditorViewModel, until condition: () -> Bool) async {
        for _ in 0..<200 where !condition() {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(5))
        }
    }

    @Test func the8890IsArranged() async throws {
        let editor = editor()
        connection.continuation.yield(.connected(Self.k8890))
        await settle(editor) { editor.isReady }
        #expect(editor.status == .connected(usb: "1189:8890", keys: nil, knobs: nil, isIdentified: true, isSimulated: false))
        #expect(editor.isChoosingLayout)
        #expect(!editor.readsBack)
        #expect(editor.availableTabs == [.keys, .media, .mouse, .lighting])
        #expect(device.reads == 0)
        let sheet = try #require(editor.layoutSheet)
        #expect(sheet.mode == .arrangement(keys: 12, columns: 4, knobs: 2, maxKeys: 12, maxKnobs: 2))
        #expect(sheet.isRequired)

        editor.chooseArrangement(keys: 6, columns: 3, knobs: 1, quarterTurns: 0)
        #expect(!editor.isChoosingLayout)
        #expect(profiles.saved[Self.k8890.usb]?.layoutID == "grid-6-3-1")
        let drawing = try #require(editor.drawing)
        #expect(drawing.controls.count == 9)

        editor.select(.key(1))
        editor.toggle(.command)
        #expect(editor.heldModifierText == "⌘")
        editor.press(Self.c)
        #expect(editor.heldModifiers.isEmpty)
        #expect(editor.selectionState?.binding == .presses(strokes: ["⌘C"], keyDelay: 0, used: 1, limit: 5))
        #expect(editor.drawing?.controls.first { $0.ref == .key(1) }?.isChanged == true)
        #expect(editor.drawing?.controls.first { $0.ref == .key(1) }?.caption == .presses("⌘C"))
        #expect(editor.hasUnsavedChanges)

        await editor.save()
        #expect(editor.notice == .saved(simulated: false))
        #expect(!editor.hasUnsavedChanges)
        #expect(device.writes.count == 1)

        // The Windows tool's keys, in its arrangement: no F13–F24, non-US keys or Keypad Enter.
        #expect(editor.vendorKeyArrangement == .alphabetical)
        #expect(editor.moreKeys.isEmpty)
        #expect(editor.keyBoard.filter { !$0.isEnabled }.map(\.face) == [.key(KeyUsage.named(0x58)!)])
        #expect(editor.keyGroups.first { $0.kind == .functionKeys }?.keys.count == 12)
        #expect(editor.keyGroups.flatMap(\.keys).count == 95)
        editor.press(KeyUsage.named(0x58)!)
        #expect(editor.notice == .unsupported)
        #expect(!editor.hasUnsavedChanges)
    }

    @Test func aStandardKeyboardIsReadOnConnect() async throws {
        device.identity = KeyboardIdentity(keyCount: 6, knobCount: 1, type: 10)
        device.actions = [.key(number: 2): .media(.mute)]
        let editor = editor()
        connection.continuation.yield(.connected(Self.k8840))
        await settle(editor) { editor.isReady && device.reads > 0 }
        #expect(editor.status == .connected(usb: "1189:8840", keys: 6, knobs: 1, isIdentified: true, isSimulated: false))
        #expect(!editor.isChoosingLayout)
        #expect(editor.layoutSheet?.mode == .fixed)
        #expect(editor.drawing?.controls.first { $0.ref == .key(2) }?.caption == .media(.mute))
        #expect(editor.availableTabs == EditorTab.allCases)
        #expect(editor.notice == nil)
        #expect(editor.vendorKeyArrangement == .qwerty)
        #expect(editor.keyBoard.allSatisfy { $0.isEnabled })
        #expect(editor.moreKeys.count == 14)

        editor.tab = .lighting
        editor.select(.key(1))
        #expect(editor.drawing?.controls.first { $0.ref == .key(1) }?.ledColor == RGB(KeyColor.defaultKeyColors[0]))
        guard case .perKeyColor(let modes, _, let keys, let selected)? = editor.lightingPage else {
            Issue.record("not the per-key page")
            return
        }
        #expect(modes == Array(0...5) && keys == 16)
        #expect(selected?.title == .key(1))
        editor.setKeyColor(RGB(red: 1, green: 2, blue: 3))
        editor.setLightingMode(4)
        guard case .perKeyColor(_, let mode, _, let changed)? = editor.lightingPage else { return }
        #expect(mode == 4 && changed?.color == RGB(red: 1, green: 2, blue: 3))

        editor.tab = .delay
        editor.press(Self.a)
        editor.press(Self.c)
        editor.setDelay(press: 1, milliseconds: 250)
        #expect(editor.delayPage == .perPress(range: 0...60000, presses: [
            PressDelay(index: 0, text: "A", delay: 0), PressDelay(index: 1, text: "C", delay: 250),
        ]))
    }

    @Test func editsNeedASelectionAndRoom() async {
        let editor = editor()
        connection.continuation.yield(.connected(Self.k8890))
        await settle(editor) { editor.isReady }
        editor.press(Self.a)
        #expect(editor.notice == .selectControlFirst)
        editor.select(.key(1))
        for _ in 0..<6 { editor.press(Self.a) }
        #expect(editor.notice == .full(5))
        #expect(editor.mediaChoices == [.playPause, .previousTrack, .nextTrack, .mute, .volumeUp, .volumeDown])
        editor.assign(.calculator)
        #expect(editor.notice == .unsupported)
        editor.assign(.mute)
        #expect(editor.selectedCaption == .media(.mute))
        editor.toggle(.shift)
        editor.assignHeldModifiers()
        #expect(editor.selectionState?.binding == .presses(strokes: ["⇧"], keyDelay: 0, used: 1, limit: 5))
        editor.press(Self.a)
        #expect(editor.selectionState?.binding == .presses(strokes: ["⇧A"], keyDelay: 0, used: 1, limit: 5))
        editor.clearSelected()
        #expect(editor.selectionState?.binding == .nothing)
        editor.select(.key(2))
        #expect(editor.selectionState?.binding == .unknown)
        editor.setLightingMode(2)
        #expect(editor.lightingPage == .modes([0, 1, 2], active: 2))
    }

    @Test func aFailedSaveKeepsTheChanges() async {
        device.failWrite = .writeFailed(code: -536_870_186)
        let editor = editor()
        connection.continuation.yield(.connected(Self.k8890))
        await settle(editor) { editor.isReady }
        await editor.save()
        #expect(editor.notice == .nothingToSave)
        editor.setLightingMode(1)
        await editor.save()
        #expect(editor.notice == .writeFailed(-536_870_186))
        #expect(editor.hasUnsavedChanges)
    }

    @Test func unpluggingForgetsTheKeyboard() async {
        let editor = editor()
        connection.continuation.yield(.connected(Self.k8890))
        await settle(editor) { editor.isReady }
        editor.select(.key(2))
        connection.continuation.yield(.searching)
        await settle(editor) { editor.status == .searching }
        #expect(editor.selectedControl == nil)
        #expect(!editor.isReady)
        #expect(editor.keyboardInfo == nil)
    }

    /// With several keyboards plugged in, each is a choice — those with the same USB ID numbered — and choosing one
    /// asks the connection to open it. One keyboard alone is no choice.
    @Test func severalKeyboardsAreChoices() async {
        let editor = editor()
        let first = AttachedKeyboard(id: "a", usb: Self.k8890.usb, location: "01100000")
        let second = AttachedKeyboard(id: "b", usb: Self.k8890.usb, location: "02100000")
        let third = AttachedKeyboard(id: "c", usb: Self.k8840.usb, location: "03100000")
        connection.attached.continuation.yield(AttachedKeyboards(keyboards: [first], selected: "a"))
        await settle(editor) { false }
        #expect(editor.keyboardChoices.isEmpty)
        connection.attached.continuation.yield(AttachedKeyboards(keyboards: [first, second, third], selected: "b"))
        await settle(editor) { editor.keyboardChoices.count == 3 }
        #expect(editor.keyboardChoices == [
            KeyboardChoice(id: "a", title: "1189:8890 (1)", isSelected: false),
            KeyboardChoice(id: "b", title: "1189:8890 (2)", isSelected: true),
            KeyboardChoice(id: "c", title: "1189:8840", isSelected: false),
        ])
        await editor.selectKeyboard("c")
        #expect(connection.selected == ["c"])
    }

    /// Unplugged, the last keyboard is still drawn, but its shape can't be changed — and its sheet goes with it.
    @Test func unpluggedTheShapeCantChange() async {
        let editor = editor()
        connection.continuation.yield(.connected(Self.k8890))
        await settle(editor) { editor.isReady }
        #expect(editor.hasLayout)
        #expect(editor.isChoosingLayout)
        connection.continuation.yield(.searching)
        await settle(editor) { editor.status == .searching }
        #expect(editor.drawing != nil)
        #expect(!editor.hasLayout)
        #expect(!editor.isChoosingLayout)
        #expect(editor.layoutSheet == nil)
    }

    /// A 884x keyboard that doesn't answer picks one of the app's layouts; rotating turns the drawing.
    @Test func theLayoutSheet() async throws {
        let editor = editor()
        connection.continuation.yield(.connected(Self.k8840))
        await settle(editor) { editor.isReady }
        guard case .catalog(let choices, let selected)? = editor.layoutSheet?.mode else {
            Issue.record("no catalog")
            return
        }
        #expect(choices.count == 26 && selected == "15add3")
        editor.chooseLayout("9add2", quarterTurns: 1)
        #expect(editor.layoutSheet?.quarterTurns == 1)
        let upright = try #require(editor.previewDrawing(layoutID: "9add2", quarterTurns: 0))
        let turned = try #require(editor.previewDrawing(layoutID: "9add2", quarterTurns: 1))
        #expect(abs(upright.bounds.width - turned.bounds.height) < 0.001)
        #expect(editor.previewDrawing(keys: 0, columns: 1, knobs: 0, quarterTurns: 0) == nil)
        editor.rotate()
        #expect(editor.layoutSheet?.quarterTurns == 2)
    }

    /// A read whose keyboard goes in the middle brings back nothing — its later layers would be the next keyboard's.
    /// A keyboard that comes meanwhile waits for the read to end, then is identified.
    @Test func aReadWhoseKeyboardChangedIsDropped() async {
        device.identity = KeyboardIdentity(keyCount: 6, knobCount: 1, type: 10)
        device.actions = [.key(number: 2): .media(.mute)]
        let editor = editor()
        connection.continuation.yield(.connected(Self.k8840))
        await settle(editor) { editor.isReady && device.reads > 0 }

        // Unplugged while the user's read is under way.
        device.actions = [.key(number: 2): .media(.volumeUp)]
        device.holds = [.read]
        let reading = Task { await editor.read() }
        await settle(editor) { device.isHolding }
        #expect(editor.activity == .reading)
        connection.continuation.yield(.searching)
        await settle(editor) { editor.status == .searching }
        device.letGo()
        await reading.value
        #expect(editor.activity == nil)
        #expect(editor.notice == .keyboardGone)
        #expect(editor.drawing?.controls.first { $0.ref == .key(2) }?.caption == .media(.mute))
        #expect(!editor.hasUnsavedChanges)

        // Another keyboard comes while the read on connecting is under way.
        device.holds = [.read]
        connection.continuation.yield(.connected(Self.k8840))
        await settle(editor) { device.isHolding }
        #expect(editor.activity == .reading)
        connection.continuation.yield(.searching)
        connection.continuation.yield(.connected(Self.k8890))
        let waiting = ConnectionStatus.connected(usb: "1189:8890", keys: nil, knobs: nil, isIdentified: false, isSimulated: false)
        await settle(editor) { editor.status == waiting }
        #expect(editor.status == waiting)
        #expect(editor.activity == .reading)
        device.letGo()
        await settle(editor) { editor.isReady }
        #expect(editor.notice == .keyboardGone)
        #expect(editor.status == .connected(usb: "1189:8890", keys: nil, knobs: nil, isIdentified: true, isSimulated: false))
    }

    /// A save whose keyboard changes in the middle isn't taken for saved — not even when the next keyboard has the
    /// same USB ID, and so looks the same.
    @Test func aSaveWhoseKeyboardChangedIsNotSaved() async {
        let editor = editor()
        connection.continuation.yield(.connected(Self.k8890))
        await settle(editor) { editor.isReady }
        editor.select(.key(1))
        editor.press(Self.a)

        device.holds = [.write]
        let saving = Task { await editor.save() }
        await settle(editor) { device.isHolding }
        #expect(editor.activity == .saving)
        connection.continuation.yield(.searching)
        await settle(editor) { editor.status == .searching }
        device.letGo()
        await saving.value
        #expect(editor.activity == nil)
        #expect(editor.notice == .keyboardGone)
        #expect(editor.hasUnsavedChanges)

        connection.continuation.yield(.connected(Self.k8890))
        await settle(editor) { editor.isReady }
        editor.select(.key(1))
        editor.press(Self.a)
        device.holds = [.write]
        let again = Task { await editor.save() }
        await settle(editor) { device.isHolding }
        connection.continuation.yield(.searching)
        connection.continuation.yield(.connected(Self.k8890))
        await settle(editor) { editor.status == .connected(usb: "1189:8890", keys: nil, knobs: nil, isIdentified: false, isSimulated: false) }
        device.letGo()
        await again.value
        #expect(editor.notice == .keyboardGone)
        #expect(editor.isReady)
    }

    /// The app stays on a keyboard while it identifies, reads or saves it: choosing another keyboard or a simulated
    /// one does nothing then.
    @Test func noSwitchingWhileBusy() async {
        device.identity = KeyboardIdentity(keyCount: 6, knobCount: 1, type: 10)
        let editor = editor()
        connection.attached.continuation.yield(Self.plugged)
        await settle(editor) { editor.keyboardChoices.count == 2 }
        #expect(editor.canSwitchKeyboard)

        device.holds = [.identity]
        connection.continuation.yield(.connected(Self.k8840))
        await settle(editor) { device.isHolding }
        #expect(editor.activity == .identifying)
        #expect(!editor.canSwitchKeyboard)
        device.letGo()
        await settle(editor) { editor.isReady }
        #expect(editor.canSwitchKeyboard)

        device.holds = [.read]
        let reading = Task { await editor.read() }
        await settle(editor) { device.isHolding }
        #expect(editor.activity == .reading)
        #expect(!editor.canSwitchKeyboard)
        await editor.selectKeyboard("b")
        await editor.selectSimulator(Self.simulated8890.id)
        #expect(connection.selected.isEmpty)
        #expect(connection.sources.isEmpty)
        #expect(editor.pendingSwitch == nil)
        device.letGo()
        await reading.value
        #expect(editor.canSwitchKeyboard)

        editor.select(.key(1))
        editor.press(Self.a)
        device.holds = [.write]
        let saving = Task { await editor.save() }
        await settle(editor) { device.isHolding }
        #expect(editor.activity == .saving)
        #expect(!editor.canSwitchKeyboard)
        device.letGo()
        await saving.value
        #expect(editor.canSwitchKeyboard)
        #expect(editor.notice == .saved(simulated: false))

        await editor.selectKeyboard("b")
        #expect(connection.selected == ["b"])
    }

    /// Going to another keyboard, or to a simulated one, with changes not saved asks first: cancelling keeps the
    /// keyboard and the changes, agreeing switches. A question is forgotten when the keyboard goes.
    @Test func switchingWithUnsavedChangesAsksFirst() async {
        let editor = editor()
        connection.attached.continuation.yield(Self.plugged)
        connection.continuation.yield(.connected(Self.k8890))
        await settle(editor) { editor.isReady && editor.keyboardChoices.count == 2 }
        editor.select(.key(1))
        editor.press(Self.a)

        await editor.selectKeyboard("b")
        #expect(editor.pendingSwitch == .keyboard("b"))
        #expect(connection.selected.isEmpty)
        editor.cancelSwitch()
        #expect(editor.pendingSwitch == nil)
        #expect(connection.selected.isEmpty)
        #expect(editor.hasUnsavedChanges)
        #expect(editor.isReady)

        await editor.selectKeyboard("b")
        await editor.confirmSwitch()
        #expect(editor.pendingSwitch == nil)
        #expect(connection.selected == ["b"])

        await editor.selectSimulator(Self.simulated8890.id)
        #expect(editor.pendingSwitch == .simulator(Self.simulated8890.id))
        #expect(connection.sources.isEmpty)
        #expect(editor.activeSimulatorID == nil)
        await editor.confirmSwitch()
        #expect(editor.pendingSwitch == nil)
        #expect(connection.sources == [.simulated(Self.simulated8890)])
        #expect(editor.activeSimulatorID == Self.simulated8890.id)

        await editor.selectSimulator(nil)
        #expect(editor.pendingSwitch == .simulator(nil))
        connection.continuation.yield(.searching)
        await settle(editor) { editor.status == .searching }
        #expect(editor.pendingSwitch == nil)
        await editor.confirmSwitch()
        #expect(connection.sources == [.simulated(Self.simulated8890)])
    }

    /// Without changes not saved there is nothing to ask; choosing what is open already does nothing.
    @Test func switchingWithoutChangesDoesntAsk() async {
        let editor = editor()
        connection.attached.continuation.yield(Self.plugged)
        connection.continuation.yield(.connected(Self.k8890))
        await settle(editor) { editor.isReady && editor.keyboardChoices.count == 2 }

        await editor.selectKeyboard("a")
        #expect(connection.selected.isEmpty)
        await editor.selectKeyboard("b")
        #expect(editor.pendingSwitch == nil)
        #expect(connection.selected == ["b"])

        await editor.selectSimulator(nil)
        #expect(connection.sources.isEmpty)
        await editor.selectSimulator(Self.simulated8890.id)
        #expect(editor.pendingSwitch == nil)
        #expect(connection.sources == [.simulated(Self.simulated8890)])
    }

    /// Once the keyboard with the changes has gone they can't be saved anywhere, so choosing another keyboard, or a
    /// simulated one, switches at once.
    @Test func changesWhoseKeyboardWentDontAsk() async {
        let editor = editor()
        connection.attached.continuation.yield(Self.plugged)
        connection.continuation.yield(.connected(Self.k8890))
        await settle(editor) { editor.isReady && editor.keyboardChoices.count == 2 }
        editor.select(.key(1))
        editor.press(Self.a)

        connection.continuation.yield(.searching)
        connection.attached.continuation.yield(AttachedKeyboards(keyboards: [
            AttachedKeyboard(id: "b", usb: Self.k8840.usb, location: "02100000"),
            AttachedKeyboard(id: "c", usb: Self.k8840.usb, location: "03100000"),
        ], selected: "b"))
        await settle(editor) { editor.status == .searching && editor.keyboardChoices.map(\.id) == ["b", "c"] }
        #expect(editor.hasUnsavedChanges)
        await editor.selectKeyboard("c")
        #expect(editor.pendingSwitch == nil)
        #expect(connection.selected == ["c"])
        await editor.selectSimulator(Self.simulated8890.id)
        #expect(editor.pendingSwitch == nil)
        #expect(connection.sources == [.simulated(Self.simulated8890)])
    }

    /// A read whose answers stop early says so — the read on connecting too — and the keys not read show what they
    /// did before.
    @Test func aReadThatStopsEarlySaysSo() async {
        device.identity = KeyboardIdentity(keyCount: 6, knobCount: 1, type: 10)
        device.actions = [.key(number: 1): .media(.mute), .key(number: 6): .media(.volumeUp)]
        device.unread = [.key(number: 6)]
        let editor = editor()
        connection.continuation.yield(.connected(Self.k8840))
        await settle(editor) { editor.isReady && device.reads > 0 }
        #expect(editor.notice == .readIncomplete)
        #expect(Notice.readIncomplete.isError)
        #expect(editor.drawing?.controls.first { $0.ref == .key(1) }?.caption == .media(.mute))
        #expect(editor.drawing?.controls.first { $0.ref == .key(6) }?.caption == .unknown)

        device.unread = []
        await editor.read()
        #expect(editor.notice == .readComplete)
        #expect(editor.drawing?.controls.first { $0.ref == .key(6) }?.caption == .media(.volumeUp))
        device.unread = [.key(number: 6)]
        await editor.read()
        #expect(editor.notice == .readIncomplete)
        #expect(editor.drawing?.controls.first { $0.ref == .key(6) }?.caption == .media(.volumeUp))
    }

    /// A keyboard that reads back is read after saving: what it holds otherwise stays changed, and the notice says
    /// which way it went.
    @Test func savingReadsBack() async {
        device.identity = KeyboardIdentity(keyCount: 6, knobCount: 1, type: 10)
        let editor = editor()
        connection.continuation.yield(.connected(Self.k8840))
        await settle(editor) { editor.isReady && device.reads > 0 }
        let readsOnConnect = device.reads

        editor.select(.key(1))
        editor.press(Self.a)
        await editor.save()
        #expect(editor.notice == .saved(simulated: false))
        #expect(device.reads == readsOnConnect + 1)
        #expect(!editor.hasUnsavedChanges)

        device.keeps = { $0 == .keys(KeyMacro([KeyStroke(key: 0x06)])) ? .unassigned : $0 }
        editor.press(Self.c)
        editor.select(.key(2))
        editor.press(Self.c)
        await editor.save()
        #expect(editor.notice == .savedButDiffers)
        #expect(editor.hasUnsavedChanges)
        #expect(editor.drawing?.controls.first { $0.ref == .key(1) }?.isChanged == false)
        #expect(editor.drawing?.controls.first { $0.ref == .key(2) }?.isChanged == true)
        #expect(editor.drawing?.controls.first { $0.ref == .key(2) }?.caption == .presses("C"))

        device.keeps = { $0 }
        device.unread = [.key(number: 2)]
        await editor.save()
        #expect(editor.notice == .savedButUnchecked)
        #expect(!editor.hasUnsavedChanges)
    }

    /// An editor on a keyboard of its own, connected to `keyboard`, for tests that try several.
    func connected(_ device: FakeDevice, _ keyboard: ConnectedKeyboard = k8840) -> KeyboardEditorViewModel {
        let connection = FakeConnection()
        let editor = KeyboardEditorViewModel(
            observeConnection: ObserveConnectionUseCase(repository: connection),
            retryConnection: RetryConnectionUseCase(repository: connection),
            identifyKeyboard: IdentifyKeyboardUseCase(repository: device, attempts: 1),
            resolveLayout: ResolveLayoutUseCase(profiles: profiles), chooseLayout: ChooseLayoutUseCase(profiles: profiles),
            readKeyboard: ReadKeyboardUseCase(repository: device), saveKeyboard: SaveKeyboardUseCase(repository: device))
        editor.start()
        connection.continuation.yield(.connected(keyboard))
        return editor
    }

    /// A keyboard of a type the app hasn't been tried on — standard (12) or legacy (9) — is said to be one once it is
    /// connected and read, in place of what the read said, for longer than an error; its information says so.
    @Test func anUntestedType() async throws {
        for (type, commands) in [(12, KeyboardInfo.Commands.standard), (9, .legacy)] {
            let device = FakeDevice()
            device.identity = KeyboardIdentity(keyCount: 6, knobCount: 1, type: type)
            device.unread = [.key(number: 6)]
            let editor = connected(device)
            await settle(editor) { editor.isReady && device.reads > 0 }
            #expect(device.reads > 0, "\(type)")
            #expect(editor.notice == .untestedFirmware(type: type), "\(type)")
            let info = try #require(editor.keyboardInfo)
            #expect(info.firmware == .reported(type: type, keys: 6, knobs: 1, isKnownType: false))
            #expect(info.commands == commands)
        }
        #expect(Notice.untestedFirmware(type: 12).lifetime == .seconds(10))
        #expect(Notice.untestedFirmware(type: 12).lifetime > Notice.readFailed.lifetime)
    }

    /// Types 10 and 11 are both the standard firmware, and known.
    @Test func knownTypes() async throws {
        for type in [10, 11] {
            let device = FakeDevice()
            device.identity = KeyboardIdentity(keyCount: 6, knobCount: 1, type: type)
            let editor = connected(device)
            await settle(editor) { editor.isReady && device.reads > 0 }
            #expect(editor.notice == nil, "\(type)")
            let info = try #require(editor.keyboardInfo)
            #expect(info.firmware == .reported(type: type, keys: 6, knobs: 1, isKnownType: true))
            #expect(info.commands == .standard)
        }
    }

    /// Every keyboard that says what it is is read as it connects, legacy firmware too, without a notice; one that
    /// doesn't say isn't read.
    @Test func identifiedKeyboardsAreReadOnConnecting() async throws {
        let legacy = FakeDevice()
        legacy.identity = KeyboardIdentity(keyCount: 6, knobCount: 1, type: 0)
        legacy.actions = [.key(number: 3): .media(.mute)]
        let editor = connected(legacy)
        await settle(editor) { editor.isReady && legacy.reads > 0 }
        #expect(legacy.reads == 3)
        #expect(editor.keyboardInfo?.commands == .legacy)
        #expect(editor.readsBack)
        #expect(editor.notice == nil)
        #expect(editor.drawing?.controls.first { $0.ref == .key(3) }?.caption == .media(.mute))

        let unidentified = FakeDevice()
        let other = connected(unidentified)
        await settle(other) { other.isReady }
        #expect(other.keyboardInfo?.commands == .unidentified)
        #expect(!other.readsBack)
        #expect(unidentified.reads == 0)
    }
}

struct GeometryTests {
    /// A knob is one body in the shape, on its press action.
    @Test func knobsAreOneBodyEach() throws {
        let sixAndOne = try #require(LayoutGeometry.of(KeyboardLayout.named("6add1")!))
        let press = try #require(sixAndOne.rects[.knob(number: 1, part: .press)])
        #expect(sixAndOne.knobOutlines.map(\.rect) == [press])
        #expect(try #require(LayoutGeometry.of(KeyboardLayout.named("0add1")!)).knobOutlines.count == 1)
        for layout in KeyboardLayout.all {
            let geometry = try #require(LayoutGeometry.of(layout), "\(layout.id)")
            #expect(Set(geometry.rects.keys) == Set(layout.controls), "\(layout.id)")
            #expect(geometry.knobOutlines.count == layout.knobCount, "\(layout.id)")
        }
    }

    /// The app's layouts with their turns redrawn: one size in a layout, each turn the gap off its knob, none
    /// over another control or out of the body.
    @Test func turnsAreEvenAndClear() throws {
        for layout in KeyboardLayout.all where GridShape(id: layout.id) == nil {
            let geometry = try #require(LayoutGeometry.of(layout), "\(layout.id)")
            let turns = geometry.rects.filter { control, _ in
                if case .knob(_, let part) = control { return part != .press }
                return false
            }
            for (control, turn) in turns {
                let name = "\(layout.id) \(control)"
                #expect(abs(turn.width - turns.first!.value.width) < 1e-9 && turn.height == turn.width, "\(name)")
                guard case .knob(let number, _) = control else { continue }
                let press = try #require(geometry.rects[.knob(number: number, part: .press)])
                let gap = LayoutGeometry.distance(turn, press) - press.width / 2 - turn.width / 2
                #expect(abs(gap - LayoutGeometry.turnGap) < 1e-6, "\(name)")
                for (other, rect) in geometry.rects where other != control {
                    if case .key = other {
                        let x = min(max(turn.midX, rect.x), rect.maxX), y = min(max(turn.midY, rect.y), rect.maxY)
                        let dx = turn.midX - x, dy = turn.midY - y
                        #expect((dx * dx + dy * dy).squareRoot() >= turn.width / 2, "\(name) over \(other)")
                    } else {
                        let clear = LayoutGeometry.distance(turn, rect) >= (turn.width + rect.width) / 2 - 1e-6
                        #expect(clear, "\(name) over \(other)")
                    }
                }
                let frame = geometry.frame
                let inside = turn.x >= frame.x && turn.y >= frame.y && turn.maxX <= frame.maxX && turn.maxY <= frame.maxY
                #expect(inside, "\(name)")
            }
        }
    }

    @Test func rotationTurnsTheGeometry() throws {
        let geometry = try #require(LayoutGeometry.of(KeyboardLayout.named("6add1")!))
        let quarter = geometry.rotated(.quarter)
        #expect(abs(quarter.bounds.width - geometry.bounds.height) < 0.001)
        #expect(abs(quarter.bounds.height - geometry.bounds.width) < 0.001)
        let full = quarter.rotated(.quarter).rotated(.quarter).rotated(.quarter)
        for (control, rect) in geometry.rects {
            let back = try #require(full.rects[control])
            #expect(abs(back.midX - rect.midX) < 0.001 && abs(back.midY - rect.midY) < 0.001)
        }
        #expect(geometry.rotated(.upright) == geometry)
    }

    /// An arrangement: keys fill the rows from the top left; a knob stands at the middle of the keys, two at
    /// the first and last rows, each with its turns either side of its press.
    @Test func arrangements() throws {
        let seven = LayoutGeometry(arrangement: try #require(GridShape(keys: 7, columns: 3, knobs: 2)))
        let key1 = try #require(seven.rects[.key(number: 1)]), key4 = try #require(seven.rects[.key(number: 4)])
        #expect(key4.x == key1.x && key4.y > key1.y)
        #expect(seven.rects[.key(number: 7)]?.x == key1.x)

        let one = LayoutGeometry(arrangement: try #require(GridShape(keys: 6, columns: 3, knobs: 1)))
        let keys = one.rects.filter { $0.key.isKey }.map(\.value)
        let middle = (keys.map(\.y).min()! + keys.map(\.maxY).max()!) / 2
        let press = try #require(one.rects[.knob(number: 1, part: .press)])
        #expect(abs(press.midY - middle) < 0.001)
        #expect(one.rects[.knob(number: 1, part: .rotateLeft)]?.midY == press.midY)

        let two = LayoutGeometry(arrangement: try #require(GridShape(keys: 12, columns: 4, knobs: 2)))
        #expect(abs(two.rects[.knob(number: 1, part: .press)]!.midY - two.rects[.key(number: 1)]!.midY) < 0.001)
        #expect(abs(two.rects[.knob(number: 2, part: .press)]!.midY - two.rects[.key(number: 9)]!.midY) < 0.001)
    }

    /// Nothing overlaps, however the keyboard is turned, and the body holds everything.
    @Test func arrangementsDontOverlap() throws {
        func overlaps(_ a: LayoutRect, _ b: LayoutRect) -> Bool {
            a.x < b.maxX && b.x < a.maxX && a.y < b.maxY && b.y < a.maxY
        }
        for keys in 0...12 {
            for columns in 1...max(keys, 1) {
                for knobs in 0...2 {
                    guard let shape = GridShape(keys: keys, columns: columns, knobs: knobs) else { continue }
                    for rotation in Rotation.allCases {
                        let geometry = LayoutGeometry(arrangement: shape).rotated(rotation)
                        #expect(Set(geometry.rects.keys) == Set(shape.layout.controls))
                        let rects = Array(geometry.rects.values)
                        for i in rects.indices {
                            for j in rects.indices where j > i {
                                #expect(!overlaps(rects[i], rects[j]), "\(shape.id) \(rotation)")
                            }
                            #expect(rects[i].x >= geometry.frame.x && rects[i].maxX <= geometry.frame.maxX + 0.001, "\(shape.id)")
                        }
                    }
                }
            }
        }
    }
}

struct DisplayTablesTests {
    @Test func strokes() {
        #expect(ActionText.stroke(KeyStroke(modifiers: [.command, .shift, .control], key: 0x1D)) == "⌃⇧⌘Z")
        #expect(ActionText.stroke(KeyStroke(modifiers: [.option, .rightCommand], key: 0)) == "⌥R⌘")
        #expect(ActionText.keys(KeyMacro([KeyStroke(key: 0x04), KeyStroke(key: 0x28)])) == "A ↩")
        #expect(ActionText.key(0xA0) == "0xA0")
    }

    @Test func keyUsagesAreUniqueAndNamed() {
        #expect(Set(KeyUsage.all.map(\.usage)).count == KeyUsage.all.count)
        #expect(KeyUsage.named(0x04)?.label == "A")
        #expect(KeyUsage.named(0x68)?.label == "F13")
        #expect(KeyUsage.named(0x73)?.label == "F24")
        #expect(KeyUsage.named(0) == nil)
    }

    /// The full-size keyboard has every key but those a full-size keyboard doesn't, each once, and no two
    /// caps overlap or run past the row.
    @Test func theFullKeyboard() {
        let places = FullKeyboard.places
        let keys = places.compactMap { place -> UInt8? in
            if case .key(let key) = place.face { return key.usage }
            return nil
        }
        let elsewhere = Set((KeyUsage.extraFunctionKeys + KeyUsage.international).map(\.usage))
        #expect(keys.count == Set(keys).count)
        #expect(Set(keys) == Set(KeyUsage.all.map(\.usage)).subtracting(elsewhere))
        #expect(Set(places.compactMap { place -> ModifierKey? in
            if case .modifier(let modifier) = place.face { return modifier }
            return nil
        }) == Set(ModifierKey.allCases))
        for row in 0..<6 {
            let caps = places.filter { $0.row == row }.sorted { $0.column < $1.column }
            let apart = zip(caps, caps.dropFirst()).allSatisfy { $0.column + $0.width <= $1.column }
            let end = caps.last.map { $0.column + $0.width } ?? 0
            #expect(apart, "row \(row)")
            #expect(end <= FullKeyboard.width, "row \(row)")
        }
    }

    /// A report in the device log: up to its zero padding on one line, every byte 16 to a row.
    @Test func packets() {
        let report: [UInt8] = [0x03, 0xFB, 0xFB, 0xFB] + Array(repeating: 0, count: 61)
        #expect(PacketText.summary(report) == "03 FB FB FB")
        #expect(PacketText.summaryCount(report) == 4)
        let rows = PacketText.rows(report)
        #expect(rows.count == 5)
        #expect(rows[0] == "0000  03 FB FB FB 00 00 00 00 00 00 00 00 00 00 00 00")
        #expect(rows[4] == "0040  00")
        #expect(PacketText.summary([0, 0]) == "00")
        #expect(PacketText.rows([]).isEmpty)
    }

    /// Every media key and mouse action the domain knows has a name on screen.
    @Test func choicesCoverTheDomain() {
        #expect(MediaKey.all.allSatisfy { MediaChoice($0) != nil })
        #expect(MediaChoice.allCases.count == MediaKey.all.count)
        #expect(MouseAction.allCases.map(MouseChoice.init).count == MouseChoice.allCases.count)
        #expect(ActionCaption(.media(MediaKey(usage: 0x999))) == .otherMedia(0x999))
        #expect(ActionCaption(nil) == .unknown)
        #expect(RGB(red: 0, green: 255, blue: 0).hex == "#00FF00")
    }

    /// The information popover, from what the 1189:8890 reports.
    @Test func keyboardInfo() {
        let keyboard = ConnectedKeyboard(
            usb: USBIdentity(vendorID: 0x1189, productID: 0x8890), family: .k8890, interfaceNumber: 1,
            channel: .usb(outEndpoint: 0x02), reportID: 3, reportLength: 65,
            details: DeviceDetails(
                usbVersion: 0x0110, deviceRelease: 0, speed: 12_000_000, manufacturer: nil, productName: nil,
                serialNumber: nil, maxPower: 100,
                interfaces: [
                    .init(number: 0, interfaceClass: 3, subclass: 1, interfaceProtocol: 1, usages: [.init(page: 1, usage: 6)]),
                    .init(number: 1, interfaceClass: 3, subclass: 0, interfaceProtocol: 0, usages: []),
                    .init(number: 2, interfaceClass: 3, subclass: 0, interfaceProtocol: 0,
                          usages: [.init(page: 1, usage: 6), .init(page: 0x0C, usage: 1)]),
                    .init(number: 3, interfaceClass: 3, subclass: 1, interfaceProtocol: 2, usages: []),
                ]))
        let info = KeyboardInfo(keyboard: keyboard, identification: KeyboardIdentification(commands: .packets(reportID: 3), identity: nil))
        #expect(info.usbID == "1189:8890")
        #expect(info.firmware == .unknown)
        #expect(info.usb == "USB 1.1 · 12 Mb/s")
        #expect(info.interfaces.map(\.roles) == [[.keyboard], [.configuration], [.keyboard, .media], [.mouse]])
        #expect(info.interfaces.map(\.isConfiguration) == [false, true, false, false])
        #expect(info.channel == KeyboardInfo.Channel(interface: 1, path: .usb(outEndpoint: 0x02), reportID: 3, reportLength: 65))
        #expect(info.commands == .packets(reportID: 3))
    }
}
