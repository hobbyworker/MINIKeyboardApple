import Testing
@testable import DataLayer
import Domain

/// The device repository against simulated firmware: the same codecs as with a keyboard on USB.
@MainActor
struct SimulatedKeyboardTests {
    static func model(_ layoutID: String, _ format: RecordFormat) -> SimulatedModel {
        SimulatedModel.identified(as: KeyboardLayout.named(layoutID)!, format: format)!
    }

    static func device(_ keyboard: SimulatedKeyboard, log: DeviceLogStore) -> KeyboardDevice {
        KeyboardDevice(channels: keyboard, log: log, identifyTimeout: .milliseconds(20), replyTimeout: .milliseconds(50), pause: { _ in })
    }

    @Test func aStandardKeyboardReadsBackWhatWasWritten() async throws {
        let log = DeviceLogStore()
        let keyboard = SimulatedKeyboard(model: Self.model("6add1", .standard), log: log)
        let device = Self.device(keyboard, log: log)
        let identity = try #require(try await device.askIdentity())
        #expect(identity == KeyboardIdentity(keyCount: 6, knobCount: 1, type: 10))

        let layout = try #require(KeyboardLayout.named("6add1"))
        let fresh = try await device.readActions(layer: 0, format: .standard, layout: layout)
        #expect(fresh.actions.count == layout.controls.count)
        #expect(fresh.actions.values.allSatisfy { $0 == .unassigned })
        #expect(fresh.unread.isEmpty)

        var configuration = KeyboardConfiguration(layerCount: 3)
        let macro = KeyMacro([KeyStroke(modifiers: .command, key: 0x06, delay: 100), KeyStroke(key: 0x28, delay: 60)])
        configuration.set(.keys(macro), for: .key(number: 3), layer: 1)
        configuration.set(.mouse(.middleClick), for: .knob(number: 1, part: .press), layer: 1)
        let colors = (0..<16).map { KeyColor(red: UInt8($0), green: 0, blue: 0) }
        configuration.setLighting(.perKey(mode: 5, colors: colors), layer: 1)
        try await device.write(configuration, commands: .records(.standard), layout: layout)

        let read = try await device.readActions(layer: 1, format: .standard, layout: layout).actions
        #expect(read[.key(number: 3)] == .keys(macro))
        #expect(read[.knob(number: 1, part: .press)] == .mouse(.middleClick))
        #expect(read[.key(number: 1)] == .unassigned)
        #expect(try await device.readLighting(layer: 1) == .perKey(mode: 5, colors: colors))
        #expect(try await device.readLighting(layer: 0) == .perKey(mode: 0, colors: KeyColor.defaultKeyColors))
    }

    @Test func aLegacyKeyboardKeepsItsWait() async throws {
        let log = DeviceLogStore()
        let keyboard = SimulatedKeyboard(model: Self.model("4add1", .legacy), log: log)
        let device = Self.device(keyboard, log: log)
        #expect(try await device.askIdentity() == KeyboardIdentity(keyCount: 4, knobCount: 1, type: 0))
        let layout = try #require(KeyboardLayout.named("4add1"))
        var configuration = KeyboardConfiguration(layerCount: 3)
        let macro = KeyMacro([KeyStroke(modifiers: .shift, key: 0x04)], delay: 1500)
        configuration.set(.keys(macro), for: .key(number: 4), layer: 2)
        configuration.setLighting(.colorMode(color: .purple, mode: 5), layer: 2)
        try await device.write(configuration, commands: .records(.legacy), layout: layout)
        let read = try await device.readActions(layer: 2, format: .legacy, layout: layout)
        #expect(read.actions[.key(number: 4)] == .keys(macro))
        #expect(read.unread.isEmpty)
        #expect(keyboard.records[3]?[0]?[11] == 0x75)
    }

    /// The legacy read asks for 24 records, so 16add3's third knob turning right, in record 25, is outside it — neither
    /// read nor unread — and a save that changes only it matches.
    @Test func aRecordBeyondTheLegacyRead() async throws {
        let log = DeviceLogStore()
        let keyboard = SimulatedKeyboard(model: Self.model("16add3", .legacy), log: log)
        let device = Self.device(keyboard, log: log)
        let layout = try #require(KeyboardLayout.named("16add3"))
        let knob = ControlID.knob(number: 3, part: .rotateRight)
        #expect(RecordNumbers.record(of: knob, in: layout) == 25)

        let read = try await device.readActions(layer: 0, format: .legacy, layout: layout)
        #expect(read.outside == [knob])
        #expect(read.unread.isEmpty)
        #expect(read.actions[knob] == nil)
        #expect(read.actions.count == layout.controls.count - 1)

        var configuration = KeyboardConfiguration(layerCount: 3)
        configuration.set(.media(.mute), for: knob, layer: 0)
        let outcome = try await SaveKeyboardUseCase(repository: device).execute(
            configuration, capabilities: KeyboardCapabilities(commands: .records(.legacy)), layout: layout)
        guard case .saved(let saved, let check) = outcome else {
            Issue.record("not saved")
            return
        }
        #expect(check == .matched)
        #expect(!saved.hasUnsavedChanges)
        #expect(keyboard.records[1]?[25]?[3] == 2)
    }

    /// Saving reads the changes back, and a simulated keyboard holds what was written — on either format.
    @Test func savingReadsBackWhatWasWritten() async throws {
        for (layoutID, format) in [("6add1", RecordFormat.standard), ("4add1", .legacy)] {
            let log = DeviceLogStore()
            let keyboard = SimulatedKeyboard(model: Self.model(layoutID, format), log: log)
            let device = Self.device(keyboard, log: log)
            let layout = try #require(KeyboardLayout.named(layoutID))
            var configuration = KeyboardConfiguration(layerCount: 3)
            configuration.set(.keys(KeyMacro([KeyStroke(modifiers: .command, key: 0x06)])), for: .key(number: 1), layer: 0)
            configuration.set(.media(.volumeUp), for: .key(number: 2), layer: 2)
            configuration.set(.mouse(.shiftWheelDown), for: .knob(number: 1, part: .rotateRight), layer: 2)
            configuration.setLighting(
                format == .standard ? .perKey(mode: 3, colors: KeyColor.defaultKeyColors.reversed())
                    : .colorMode(color: .blue, mode: 2),
                layer: 1)
            let outcome = try await SaveKeyboardUseCase(repository: device).execute(
                configuration, capabilities: KeyboardCapabilities(commands: .records(format)), layout: layout)
            guard case .saved(let saved, let check) = outcome else {
                Issue.record("not saved: \(format)")
                continue
            }
            #expect(check == .matched, "\(format)")
            #expect(!saved.hasUnsavedChanges, "\(format)")
        }
    }

    @Test func anUnidentifiedKeyboardAnswersNothing() async throws {
        let log = DeviceLogStore()
        let model = SimulatedModel(usb: USBIdentity(vendorID: 0x1189, productID: 0x8840), kind: .unidentified)
        let keyboard = SimulatedKeyboard(model: model, log: log)
        let device = Self.device(keyboard, log: log)
        #expect(try await device.askIdentity() == nil)
        var configuration = KeyboardConfiguration(layerCount: 3)
        configuration.set(.media(.mute), for: .key(number: 1), layer: 0)
        try await device.write(configuration, commands: .records(.unidentified), layout: KeyboardLayout.named("6add1")!)
        #expect(keyboard.records[1]?[1]?[0] == 0xFE)
    }

    /// The 8890's packets go out after its report ID, padded to its report's length.
    @Test func the8890() async throws {
        let log = DeviceLogStore()
        let model = SimulatedModel(usb: USBIdentity(vendorID: 0x1189, productID: 0x8890), kind: .k8890(reportID: 3))
        let keyboard = SimulatedKeyboard(model: model, log: log)
        let device = Self.device(keyboard, log: log)
        var configuration = KeyboardConfiguration(layerCount: 3)
        configuration.set(.keys(KeyMacro([KeyStroke(key: 0x04)])), for: .key(number: 1), layer: 0)
        try await device.write(configuration, commands: .packets(reportID: 3), layout: KeyboardLayout.named("6add1")!)
        #expect(keyboard.written.count == 4)
        #expect(keyboard.written.allSatisfy { $0.count == 64 })
        #expect(Array(keyboard.written[2].prefix(8)) == [1, 0x11, 1, 1, 0, 0x04, 0, 0])
        var entries: [DeviceLogEntry] = []
        for await list in await log.entries() {
            entries = list
            break
        }
        let written = entries.compactMap { entry -> [UInt8]? in
            if case .output(let report) = entry.content { return report }
            return nil
        }
        #expect(written.count == 4)
        #expect(written.first == [0x03, 0xA1, 0x01] + Array(repeating: 0, count: 62))
    }

    @Test func nothingOpen() async {
        final class Nothing: ChannelProvider {
            var openChannel: (any ReportChannel)? { nil }
        }
        let device = KeyboardDevice(channels: Nothing(), log: DeviceLogStore())
        await #expect(throws: KeyboardDeviceError.notConnected) { try await device.askIdentity() }
    }

    @Test func everyModelHasAKeyboard() {
        #expect(SimulatedModel.all.count > 40)
        #expect(Set(SimulatedModel.all.map(\.id)).count == SimulatedModel.all.count)
        #expect(SimulatedModel.all.allSatisfy { KeyboardFamily(usb: $0.usb) != nil })
        #expect(SimulatedModel.identified(as: KeyboardLayout.named("4add1")!, format: .standard) == nil)
    }
}

/// A keyboard that answers every request with the payloads it is given — as many as it gets to.
@MainActor
final class ScriptedKeyboard: ReportChannel, ChannelProvider {
    let framing = ReportFraming(reportID: K884xCommands.reportID, length: K884xCommands.reportLength)
    var answers: [[UInt8]] = []
    private let replies = ReplyQueue()

    var openChannel: (any ReportChannel)? { self }

    func write(_ report: [UInt8]) async throws(KeyboardDeviceError) {
        answers.forEach { replies.receive(framing.frame($0)) }
    }

    func discardPendingReplies() {
        replies.discard()
    }

    func nextReply(timeout: Duration) async -> [UInt8]? {
        await replies.next(timeout: timeout)
    }
}

/// Reading a layer when the keyboard answers less than asked, and the form a record keeps an action in.
@MainActor
struct LayerReadTests {
    static let layout = KeyboardLayout.named("6add1")!

    static func records(_ ids: ClosedRange<Int>, format: RecordFormat = .standard) throws -> [[UInt8]] {
        try ids.map { try RecordCodec.encode(.media(.mute), recordID: $0, layer: 0, format: format) }
    }

    static func read(_ keyboard: ScriptedKeyboard, format: RecordFormat = .standard) async throws(KeyboardDeviceError) -> LayerRead {
        try await KeyboardDevice(channels: keyboard, log: DeviceLogStore(), replyTimeout: .milliseconds(30), pause: { _ in })
            .readActions(layer: 0, format: format, layout: layout)
    }

    /// Answers that stop after four records: those four are read, the layout's other controls unread.
    @Test func answersThatStopEarly() async throws {
        let keyboard = ScriptedKeyboard()
        keyboard.answers = try Self.records(1...4)
        let read = try await Self.read(keyboard)
        #expect(Set(read.actions.keys) == Set((1...4).map { ControlID.key(number: $0) }))
        #expect(read.actions.values.allSatisfy { $0 == .media(.mute) })
        #expect(read.unread == Set(Self.layout.controls).subtracting(read.actions.keys))
        #expect(read.unread.count == 5)
    }

    /// A keyboard that answers as far as its last control's record has read everything.
    @Test func answersAsFarAsTheLastControl() async throws {
        let keyboard = ScriptedKeyboard()
        keyboard.answers = try Self.records(1...18, format: .legacy)
        let read = try await Self.read(keyboard, format: .legacy)
        #expect(read.actions.count == Self.layout.controls.count)
        #expect(read.unread.isEmpty)
    }

    @Test func noAnswer() async {
        await #expect(throws: KeyboardDeviceError.noReply) { try await Self.read(ScriptedKeyboard()) }
    }

    /// A record of a kind the app doesn't know leaves its control unread.
    @Test func anUnknownKind() async throws {
        let keyboard = ScriptedKeyboard()
        var answers = try Self.records(1...25)
        answers[1][3] = 9
        keyboard.answers = answers
        let read = try await Self.read(keyboard)
        #expect(read.unread == [.key(number: 2)])
        #expect(read.actions.count == Self.layout.controls.count - 1)
    }

    /// Well-formed actions of every kind come back as they went, in what each format keeps of them.
    @Test func storedForm() {
        let device = KeyboardDevice(channels: ScriptedKeyboard(), log: DeviceLogStore())
        let common: [KeyAction] = [.unassigned, .keys(KeyMacro([KeyStroke(modifiers: [.control, .option], key: 0)]))]
            + MediaKey.all.map(KeyAction.media) + MouseAction.allCases.map(KeyAction.mouse)
        let standard = common + [
            .keys(KeyMacro([KeyStroke(modifiers: [.shift, .command], key: 0x1D, delay: 300), KeyStroke(key: 0x28, delay: 50)])),
        ]
        let legacy = common + [
            .keys(KeyMacro([KeyStroke(modifiers: .control, key: 0x06), KeyStroke(modifiers: .rightShift, key: 0x19)], delay: 500)),
        ]
        for action in standard {
            #expect(device.storedForm(of: action, format: .standard) == action, "\(action)")
        }
        for action in legacy {
            #expect(device.storedForm(of: action, format: .legacy) == action, "\(action)")
        }
        // What a format doesn't keep is left out: legacy records keep no wait per press, standard ones none per key.
        let press = KeyStroke(key: 0x04)
        #expect(device.storedForm(of: .keys(KeyMacro([KeyStroke(key: 0x04, delay: 100)])), format: .legacy) == .keys(KeyMacro([press])))
        #expect(device.storedForm(of: .keys(KeyMacro([press], delay: 100)), format: .standard) == .keys(KeyMacro([press])))
        // More presses than a record holds.
        #expect(device.storedForm(of: .keys(KeyMacro(Array(repeating: press, count: 19))), format: .standard) == nil)
    }
}

/// The descriptors a 1189:8890 reports. Interfaces 0, 2 and 3 are its keyboard, keyboard + consumer and
/// mouse; interface 1, where settings are written, is HID class with only an interrupt OUT endpoint.
struct USBDescriptorTests {
    static let configuration: [UInt8] = [
        0x09, 0x02, 0x6D, 0x00, 0x04, 0x01, 0x00, 0xA0, 0x32, 0x09, 0x04, 0x00, 0x00, 0x01, 0x03, 0x01,
        0x01, 0x00, 0x09, 0x21, 0x11, 0x01, 0x00, 0x01, 0x22, 0x40, 0x00, 0x07, 0x05, 0x81, 0x03, 0x40,
        0x00, 0x0A, 0x09, 0x04, 0x01, 0x00, 0x01, 0x03, 0x00, 0x00, 0x00, 0x09, 0x21, 0x00, 0x01, 0x00,
        0x01, 0x22, 0x24, 0x00, 0x07, 0x05, 0x02, 0x03, 0x40, 0x00, 0x0A, 0x09, 0x04, 0x02, 0x00, 0x01,
        0x03, 0x00, 0x00, 0x00, 0x09, 0x21, 0x00, 0x01, 0x00, 0x01, 0x22, 0x56, 0x00, 0x07, 0x05, 0x83,
        0x03, 0x04, 0x00, 0x0A, 0x09, 0x04, 0x03, 0x00, 0x01, 0x03, 0x01, 0x02, 0x00, 0x09, 0x21, 0x10,
        0x01, 0x00, 0x01, 0x22, 0x34, 0x00, 0x07, 0x05, 0x82, 0x03, 0x04, 0x00, 0x0A,
    ]

    /// Interface 1: vendor page 0xFF00, report ID 3 with 64 bytes in and 64 bytes out.
    static let configurationReport: [UInt8] = [
        0x06, 0x00, 0xFF, 0x09, 0x01, 0xA1, 0x01, 0x85, 0x03, 0x09, 0x02, 0x15, 0x00, 0x26, 0x00, 0xFF,
        0x75, 0x08, 0x95, 0x40, 0x81, 0x06, 0x09, 0x02, 0x15, 0x00, 0x26, 0x00, 0xFF, 0x75, 0x08, 0x95,
        0x40, 0x91, 0x06, 0xC0,
    ]

    @Test func configurationInterfaceHasOnlyAnOutEndpoint() throws {
        let interface = try #require(USBDescriptors.interface(1, inConfiguration: Self.configuration))
        #expect(interface.outEndpoint == USBDescriptors.Endpoint(address: 0x02, maxPacketSize: 64))
        #expect(interface.reportDescriptorLength == 36)
    }

    @Test func inputInterfacesHaveNoOutEndpoint() throws {
        for number in [0, 2, 3] {
            let interface = try #require(USBDescriptors.interface(number, inConfiguration: Self.configuration))
            #expect(interface.outEndpoint == nil)
        }
        #expect(USBDescriptors.interface(4, inConfiguration: Self.configuration) == nil)
    }

    @Test func outputReportIsID3With64Bytes() {
        #expect(HIDReportDescriptor.firstOutputReport(in: Self.configurationReport)
            == HIDReportDescriptor.OutputReport(id: 3, length: 64))
    }

    /// The configuration interface is told from the others by its vendor-defined page.
    @Test func configurationReportIsVendorDefined() {
        #expect(HIDReportDescriptor.usagePage(in: Self.configurationReport) == 0xFF00)
        let mouse: [UInt8] = [0x05, 0x01, 0x09, 0x02, 0xA1, 0x01, 0x75, 0x08, 0x95, 0x04, 0x81, 0x06, 0xC0]
        #expect(HIDReportDescriptor.usagePage(in: mouse) == 0x01)
        #expect(HIDReportDescriptor.usagePage(in: []) == nil)
    }

    /// Firmware without report IDs: the output report is unnumbered.
    @Test func unnumberedOutputReportIsID0() {
        let report: [UInt8] = [0x06, 0x00, 0xFF, 0x09, 0x01, 0xA1, 0x01, 0x75, 0x08, 0x95, 0x08, 0x91, 0x02, 0xC0]
        #expect(HIDReportDescriptor.firstOutputReport(in: report) == HIDReportDescriptor.OutputReport(id: 0, length: 8))
    }

    @Test func inputOnlyDescriptorHasNoOutputReport() {
        let mouse: [UInt8] = [0x05, 0x01, 0x09, 0x02, 0xA1, 0x01, 0x75, 0x08, 0x95, 0x04, 0x81, 0x06, 0xC0]
        #expect(HIDReportDescriptor.firstOutputReport(in: mouse) == nil)
    }
}
