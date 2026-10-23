import Testing
@testable import Domain

struct EditingTests {
    static let key1 = ControlID.key(number: 1)

    static func target(_ commands: CommandSet, control: ControlID? = key1, layer: Int = 0) -> EditTarget {
        EditTarget(capabilities: KeyboardCapabilities(commands: commands), layer: layer, control: control)
    }

    @Test func pressesAddUp() {
        var configuration = KeyboardConfiguration(layerCount: 3)
        let target = Self.target(.records(.standard))
        #expect(AppendStrokeUseCase().execute(KeyStroke(modifiers: .command, key: 0x06), in: &configuration, at: target) == .applied)
        #expect(AppendStrokeUseCase().execute(KeyStroke(key: 0x28), in: &configuration, at: target) == .applied)
        #expect(configuration.action(Self.key1, layer: 0)
            == .keys(KeyMacro([KeyStroke(modifiers: .command, key: 0x06), KeyStroke(key: 0x28)])))
        #expect(configuration.isChanged(Self.key1, layer: 0))
        #expect(configuration.action(Self.key1, layer: 1) == nil)
    }

    @Test func nothingWithoutASelection() {
        var configuration = KeyboardConfiguration(layerCount: 3)
        let target = Self.target(.records(.standard), control: nil)
        #expect(AppendStrokeUseCase().execute(KeyStroke(key: 0x04), in: &configuration, at: target) == .needsSelection)
        #expect(!configuration.hasUnsavedChanges)
    }

    /// Modifiers alone make a key a modifier key; a key pressed next takes them, as the vendor tools'
    /// modifier buttons work.
    @Test func modifiersAlone() {
        var configuration = KeyboardConfiguration(layerCount: 3)
        let target = Self.target(.packets(reportID: 3))
        #expect(AppendStrokeUseCase().execute(KeyStroke(modifiers: .control, key: 0), in: &configuration, at: target) == .applied)
        #expect(configuration.action(Self.key1, layer: 0) == .keys(KeyMacro([KeyStroke(modifiers: .control, key: 0)])))
        #expect(AppendStrokeUseCase().execute(KeyStroke(modifiers: .shift, key: 0x06), in: &configuration, at: target) == .applied)
        #expect(configuration.action(Self.key1, layer: 0) == .keys(KeyMacro([KeyStroke(modifiers: [.control, .shift], key: 0x06)])))
        #expect(AppendStrokeUseCase().execute(KeyStroke(modifiers: .option, key: 0), in: &configuration, at: target) == .modifiersOnlyAlone)
    }

    /// A key the keyboard's vendor tool doesn't offer isn't added, pressed or set as a whole action.
    @Test func aKeyTheKeyboardIsNotGivenStaysOut() {
        var configuration = KeyboardConfiguration(layerCount: 3)
        let k8890 = Self.target(.packets(reportID: 3))
        #expect(AppendStrokeUseCase().execute(KeyStroke(key: 0x68), in: &configuration, at: k8890) == .unsupported)
        #expect(SetActionUseCase().execute(.keys(KeyMacro([KeyStroke(key: 0x58)])), in: &configuration, at: k8890) == .unsupported)
        #expect(!configuration.hasUnsavedChanges)
        #expect(AppendStrokeUseCase().execute(KeyStroke(key: 0x68), in: &configuration, at: Self.target(.records(.standard))) == .applied)
    }

    @Test func aFullKeyTakesNoMore() {
        var configuration = KeyboardConfiguration(layerCount: 3)
        let target = Self.target(.packets(reportID: 3))
        for _ in 0..<5 {
            #expect(AppendStrokeUseCase().execute(KeyStroke(key: 0x04), in: &configuration, at: target) == .applied)
        }
        #expect(AppendStrokeUseCase().execute(KeyStroke(key: 0x04), in: &configuration, at: target) == .full(5))
    }

    @Test func aMediaKeyReplacesPresses() {
        var configuration = KeyboardConfiguration(layerCount: 3)
        let target = Self.target(.packets(reportID: 3))
        _ = AppendStrokeUseCase().execute(KeyStroke(key: 0x04), in: &configuration, at: target)
        #expect(SetActionUseCase().execute(.media(.mute), in: &configuration, at: target) == .applied)
        #expect(configuration.action(Self.key1, layer: 0) == .media(.mute))
        // The 8890 knows six media keys.
        #expect(SetActionUseCase().execute(.media(.calculator), in: &configuration, at: target) == .unsupported)
        // A key pressed now starts over.
        _ = AppendStrokeUseCase().execute(KeyStroke(key: 0x05), in: &configuration, at: target)
        #expect(configuration.action(Self.key1, layer: 0) == .keys(KeyMacro([KeyStroke(key: 0x05)])))
    }

    @Test func removingPresses() {
        var configuration = KeyboardConfiguration(layerCount: 3)
        let target = Self.target(.records(.legacy))
        _ = AppendStrokeUseCase().execute(KeyStroke(key: 0x04), in: &configuration, at: target)
        _ = AppendStrokeUseCase().execute(KeyStroke(key: 0x05), in: &configuration, at: target)
        #expect(RemoveLastStrokeUseCase().execute(in: &configuration, at: target) == .applied)
        #expect(configuration.action(Self.key1, layer: 0) == .keys(KeyMacro([KeyStroke(key: 0x04)])))
        #expect(RemoveLastStrokeUseCase().execute(in: &configuration, at: target) == .applied)
        #expect(configuration.action(Self.key1, layer: 0) == .unassigned)
        #expect(RemoveLastStrokeUseCase().execute(in: &configuration, at: target) == .unsupported)
    }

    @Test func delays() {
        var configuration = KeyboardConfiguration(layerCount: 3)
        let standard = Self.target(.records(.standard))
        _ = AppendStrokeUseCase().execute(KeyStroke(key: 0x04), in: &configuration, at: standard)
        _ = AppendStrokeUseCase().execute(KeyStroke(key: 0x05), in: &configuration, at: standard)
        #expect(SetPressDelayUseCase().execute(press: 1, milliseconds: 70000, in: &configuration, at: standard) == .applied)
        #expect(configuration.action(Self.key1, layer: 0)
            == .keys(KeyMacro([KeyStroke(key: 0x04), KeyStroke(key: 0x05, delay: 60000)])))
        #expect(SetKeyDelayUseCase().execute(milliseconds: 100, in: &configuration, at: standard) == .unsupported)

        let legacy = Self.target(.records(.legacy))
        #expect(SetKeyDelayUseCase().execute(milliseconds: 9000, in: &configuration, at: legacy) == .applied)
        if case .keys(let macro)? = configuration.action(Self.key1, layer: 0) {
            #expect(macro.delay == 6000)
        } else {
            Issue.record("the key lost its presses")
        }
        #expect(SetPressDelayUseCase().execute(press: 0, milliseconds: 5, in: &configuration, at: Self.target(.packets(reportID: 3))) == .unsupported)
    }

    @Test func clearing() throws {
        var configuration = KeyboardConfiguration(layerCount: 3)
        let target = Self.target(.records(.standard))
        #expect(ClearUseCase().execute(in: &configuration, at: target) == .applied)
        #expect(configuration.action(Self.key1, layer: 0) == .unassigned)
        let layout = try #require(KeyboardLayout.named("6add1"))
        _ = ClearUseCase().executeAll(layout, in: &configuration, layer: 2)
        #expect(layout.controls.allSatisfy { configuration.action($0, layer: 2) == .unassigned })
        #expect(configuration.action(.knob(number: 1, part: .press), layer: 2) == .unassigned)
        configuration.markSaved()
        #expect(!configuration.hasUnsavedChanges)
    }

    @Test func lighting() throws {
        var configuration = KeyboardConfiguration(layerCount: 3)
        let k8890 = Self.target(.packets(reportID: 3))
        #expect(SetLightingUseCase().execute(mode: 2, in: &configuration, at: k8890) == .applied)
        #expect(configuration.lighting(layer: 0) == .mode(2))
        #expect(SetLightingUseCase().execute(mode: 3, in: &configuration, at: k8890) == .unsupported)

        let legacy = Self.target(.records(.legacy), layer: 1)
        #expect(SetLightingUseCase().execute(color: .red, in: &configuration, at: legacy) == .applied)
        #expect(SetLightingUseCase().execute(mode: 4, in: &configuration, at: legacy) == .applied)
        #expect(configuration.lighting(layer: 1) == .colorMode(color: .red, mode: 4))

        let color = KeyColor(red: 1, green: 2, blue: 3)
        let standard = Self.target(.records(.standard), control: .key(number: 16), layer: 2)
        #expect(SetLightingUseCase().execute(keyColor: color, in: &configuration, at: standard) == .applied)
        guard case .perKey(let mode, let colors)? = configuration.lighting(layer: 2) else {
            Issue.record("no colours")
            return
        }
        #expect(mode == 0)
        #expect(colors[15] == color)
        let knob = Self.target(.records(.standard), control: .knob(number: 1, part: .press), layer: 2)
        #expect(SetLightingUseCase().execute(keyColor: color, in: &configuration, at: knob) == .needsColorKey(16))
    }

    @Test func readingReplacesWhatTheAppHad() {
        var configuration = KeyboardConfiguration(layerCount: 3)
        configuration.set(.media(.mute), for: Self.key1, layer: 0)
        configuration.applyRead([Self.key1: .mouse(.leftClick)], layer: 0)
        #expect(configuration.action(Self.key1, layer: 0) == .mouse(.leftClick))
        #expect(!configuration.hasUnsavedChanges)
    }
}

/// A keyboard that answers as told.
final class FakeDevice: KeyboardDeviceRepository, @unchecked Sendable {
    var identities: [Result<KeyboardIdentity?, KeyboardDeviceError>] = []
    var actions: [ControlID: KeyAction] = [:]
    var lightingResult: LayerLighting = .perKey(mode: 1, colors: KeyColor.defaultKeyColors)
    var failRead: KeyboardDeviceError?
    var failWrite: KeyboardDeviceError?
    private(set) var asked = 0
    private(set) var writes: [KeyboardConfiguration] = []

    func askIdentity() async throws(KeyboardDeviceError) -> KeyboardIdentity? {
        asked += 1
        guard !identities.isEmpty else { return nil }
        return try identities.removeFirst().get()
    }

    func readActions(layer: Int, format: RecordFormat, layout: KeyboardLayout) async throws(KeyboardDeviceError) -> [ControlID: KeyAction] {
        if let failRead { throw failRead }
        return actions
    }

    func readLighting(layer: Int) async throws(KeyboardDeviceError) -> LayerLighting { lightingResult }

    func write(_ configuration: KeyboardConfiguration, commands: CommandSet, layout: KeyboardLayout) async throws(KeyboardDeviceError) {
        if let failWrite { throw failWrite }
        writes.append(configuration)
    }
}

struct DeviceUseCaseTests {
    static let k884x = ConnectedKeyboard(
        usb: USBIdentity(vendorID: 0x1189, productID: 0x8840), family: .k884x, interfaceNumber: 0, channel: .hid,
        reportID: 3, reportLength: 65, details: nil)
    static let k8890 = ConnectedKeyboard(
        usb: USBIdentity(vendorID: 0x1189, productID: 0x8890), family: .k8890, interfaceNumber: 1,
        channel: .usb(outEndpoint: 2), reportID: 3, reportLength: 65, details: nil)

    @Test func the8890IsAskedNothing() async throws {
        let device = FakeDevice()
        let identification = try await IdentifyKeyboardUseCase(repository: device).execute(Self.k8890)
        #expect(identification.commands == .packets(reportID: 3))
        #expect(device.asked == 0)
    }

    @Test func a884xKeyboardIsAskedUntilItAnswers() async throws {
        let device = FakeDevice()
        let identity = KeyboardIdentity(keyCount: 6, knobCount: 1, type: 10)
        device.identities = [.failure(.invalidReply), .success(nil), .success(identity)]
        let identification = try await IdentifyKeyboardUseCase(repository: device).execute(Self.k884x)
        #expect(identification == KeyboardIdentification(commands: .records(.standard), identity: identity))
        #expect(device.asked == 3)
    }

    @Test func aKeyboardThatNeverAnswersTakesFERecords() async throws {
        let device = FakeDevice()
        let identification = try await IdentifyKeyboardUseCase(repository: device).execute(Self.k884x)
        #expect(identification == KeyboardIdentification(commands: .records(.unidentified), identity: nil))
        #expect(device.asked == 3)
    }

    @Test func aWriteFailureEndsTheAsking() async {
        let device = FakeDevice()
        device.identities = [.failure(.writeFailed(code: 1))]
        await #expect(throws: KeyboardDeviceError.writeFailed(code: 1)) {
            try await IdentifyKeyboardUseCase(repository: device).execute(Self.k884x)
        }
        #expect(device.asked == 1)
    }

    @Test func readingTheStandardFormatReadsLightsToo() async throws {
        let device = FakeDevice()
        device.actions = [.key(number: 1): .media(.mute)]
        let layout = try #require(KeyboardLayout.named("6add1"))
        let outcome = await ReadKeyboardUseCase(repository: device).execute(
            KeyboardConfiguration(layerCount: 3), capabilities: KeyboardCapabilities(commands: .records(.standard)), layout: layout)
        #expect(outcome.error == nil)
        #expect(outcome.configuration.action(.key(number: 1), layer: 2) == .media(.mute))
        #expect(outcome.configuration.lighting(layer: 1) == device.lightingResult)

        let legacy = await ReadKeyboardUseCase(repository: device).execute(
            KeyboardConfiguration(layerCount: 3), capabilities: KeyboardCapabilities(commands: .records(.legacy)), layout: layout)
        #expect(legacy.configuration.lighting(layer: 0) == nil)

        let k8890 = await ReadKeyboardUseCase(repository: device).execute(
            KeyboardConfiguration(layerCount: 3), capabilities: KeyboardCapabilities(commands: .packets(reportID: 3)), layout: layout)
        #expect(k8890.error == .unsupported)
    }

    @Test func savingMarksTheChangesSaved() async throws {
        let device = FakeDevice()
        let layout = try #require(KeyboardLayout.named("6add1"))
        let capabilities = KeyboardCapabilities(commands: .records(.standard))
        var configuration = KeyboardConfiguration(layerCount: 3)
        #expect(try await SaveKeyboardUseCase(repository: device).execute(configuration, capabilities: capabilities, layout: layout) == .nothingToSave)
        configuration.set(.media(.mute), for: .key(number: 1), layer: 0)
        guard case .saved(let saved) = try await SaveKeyboardUseCase(repository: device).execute(configuration, capabilities: capabilities, layout: layout) else {
            Issue.record("not saved")
            return
        }
        #expect(!saved.hasUnsavedChanges)
        #expect(saved.action(.key(number: 1), layer: 0) == .media(.mute))
        #expect(device.writes == [configuration])

        device.failWrite = .writeFailed(code: 7)
        await #expect(throws: KeyboardDeviceError.writeFailed(code: 7)) {
            try await SaveKeyboardUseCase(repository: device).execute(configuration, capabilities: capabilities, layout: layout)
        }
    }
}
