import Testing
@testable import Presentation
import Domain

/// A keyboard that is plugged in when asked.
final class FakeConnection: KeyboardConnectionRepository, @unchecked Sendable {
    let continuation: AsyncStream<ConnectionState>.Continuation
    let stream: AsyncStream<ConnectionState>

    init() {
        (stream, continuation) = AsyncStream.makeStream(of: ConnectionState.self)
        continuation.yield(.searching)
    }

    func connectionStates() async -> AsyncStream<ConnectionState> { stream }
    func retry() async {}
}

final class FakeDevice: KeyboardDeviceRepository, @unchecked Sendable {
    var identity: KeyboardIdentity?
    var actions: [ControlID: KeyAction] = [:]
    var failWrite: KeyboardDeviceError?
    private(set) var writes: [KeyboardConfiguration] = []
    private(set) var reads = 0

    func askIdentity() async throws(KeyboardDeviceError) -> KeyboardIdentity? { identity }

    func readActions(layer: Int, format: RecordFormat, layout: KeyboardLayout) async throws(KeyboardDeviceError) -> [ControlID: KeyAction] {
        reads += 1
        return actions
    }

    func readLighting(layer: Int) async throws(KeyboardDeviceError) -> LayerLighting {
        .perKey(mode: 0, colors: KeyColor.defaultKeyColors)
    }

    func write(_ configuration: KeyboardConfiguration, commands: CommandSet, layout: KeyboardLayout) async throws(KeyboardDeviceError) {
        if let failWrite { throw failWrite }
        writes.append(configuration)
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

    func editor() -> KeyboardEditorViewModel {
        let editor = KeyboardEditorViewModel(
            observeConnection: ObserveConnectionUseCase(repository: connection),
            retryConnection: RetryConnectionUseCase(repository: connection),
            identifyKeyboard: IdentifyKeyboardUseCase(repository: device, attempts: 1),
            resolveLayout: ResolveLayoutUseCase(profiles: profiles), chooseLayout: ChooseLayoutUseCase(profiles: profiles),
            readKeyboard: ReadKeyboardUseCase(repository: device), saveKeyboard: SaveKeyboardUseCase(repository: device))
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
        #expect(editor.notice == .saved)
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
