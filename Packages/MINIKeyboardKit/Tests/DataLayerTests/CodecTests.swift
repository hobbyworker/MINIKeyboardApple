import Testing
@testable import DataLayer
import Domain

/// The 1189:8890's packets, as the Windows tool sends them.
struct K8890PacketTests {
    @Test func aKeyIsTheLayerItsGroupsAndTheSave() throws {
        let packets = try K8890Packets.download(
            number: 3, action: .keys(KeyMacro([KeyStroke(modifiers: .command, key: 0x06), KeyStroke(key: 0x28)])),
            layer: 1, reportID: 3)
        #expect(packets == [
            [0xA1, 0x02, 0, 0, 0, 0, 0, 0],
            [0x03, 0x21, 0x02, 0x00, 0x08, 0x00, 0, 0],
            [0x03, 0x21, 0x02, 0x01, 0x08, 0x06, 0, 0],
            [0x03, 0x21, 0x02, 0x02, 0x00, 0x28, 0, 0],
            [0xAA, 0xAA, 0, 0, 0, 0, 0, 0],
        ])
    }

    /// Report ID 0 takes no layer switch and no layer in the type byte.
    @Test func reportIDZeroHasNoLayers() throws {
        let packets = try K8890Packets.download(number: 1, action: .keys(KeyMacro([KeyStroke(key: 0x04)])), layer: 2, reportID: 0)
        #expect(packets.first == [0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0, 0])
        #expect(packets.count == 3)
    }

    @Test func modifiersAloneAndClearedKeys() throws {
        #expect(try K8890Packets.keyPackets(number: 14, action: .keys(KeyMacro([KeyStroke(modifiers: [.control, .shift], key: 0)])), layer: 0, reportID: 3)
            == [[14, 0x11, 0, 0, 0x03, 0, 0, 0]])
        #expect(try K8890Packets.keyPackets(number: 14, action: .unassigned, layer: 0, reportID: 3)
            == [[14, 0x11, 0, 0, 0, 0, 0, 0]])
    }

    @Test func mediaKeysPerReportID() throws {
        #expect(try K8890Packets.keyPackets(number: 2, action: .media(.playPause), layer: 0, reportID: 3) == [[2, 0x12, 0xCD, 0x00, 0, 0, 0, 0]])
        #expect(try K8890Packets.keyPackets(number: 2, action: .media(.playPause), layer: 0, reportID: 0) == [[2, 0x02, 0x40, 0x00, 0, 0, 0, 0]])
        #expect(try K8890Packets.keyPackets(number: 2, action: .media(.volumeDown), layer: 0, reportID: 2) == [[2, 0x12, 0x80, 0x00, 0, 0, 0, 0]])
        #expect(throws: KeyboardDeviceError.unsupported) {
            try K8890Packets.keyPackets(number: 2, action: .media(.calculator), layer: 0, reportID: 2)
        }
    }

    @Test func mouse() throws {
        #expect(try K8890Packets.keyPackets(number: 4, action: .mouse(.shiftWheelDown), layer: 0, reportID: 3)
            == [[4, 0x13, 0x00, 0, 0, 0xFF, 0x02, 0]])
        #expect(try K8890Packets.keyPackets(number: 4, action: .mouse(.rightClick), layer: 0, reportID: 3)
            == [[4, 0x13, 0x02, 0, 0, 0x00, 0x00, 0]])
    }

    /// The lights, their save, and a save with no key in it (it ends the key repeat the lights' save starts).
    @Test func lighting() {
        #expect(K8890Packets.downloadLighting(mode: 2, layer: 0, reportID: 3) == [
            [0xA1, 0x01, 0, 0, 0, 0, 0, 0], [0xB0, 0x18, 0x02, 0, 0, 0, 0, 0], [0xAA, 0xA1, 0, 0, 0, 0, 0, 0],
            [0xA1, 0x01, 0, 0, 0, 0, 0, 0], [0xAA, 0xAA, 0, 0, 0, 0, 0, 0],
        ])
    }

    /// With the setting off, just what the vendor's tool sends.
    @Test func lightingAsTheVendorsTool() {
        #expect(K8890Packets.downloadLighting(mode: 2, layer: 0, reportID: 3, endsKeyRepeat: false) == [
            [0xA1, 0x01, 0, 0, 0, 0, 0, 0], [0xB0, 0x18, 0x02, 0, 0, 0, 0, 0], [0xAA, 0xA1, 0, 0, 0, 0, 0, 0],
        ])
    }
}

/// The 884x records, as the cross-platform app writes and reads them.
struct RecordCodecTests {
    @Test func standardEntriesTakeAModifierEach() throws {
        let macro = KeyMacro([KeyStroke(modifiers: [.shift, .command], key: 0x1D, delay: 300), KeyStroke(key: 0x28, delay: 50)])
        let record = try RecordCodec.standard(.keys(macro), recordID: 4, layer: 2)
        #expect(record.count == 64)
        #expect(Array(record[0..<6]) == [0xFD, 4, 3, 1, 0, 4])
        #expect(Array(record[6..<18]) == [0x01, 0x2C, 0xF2, 0x00, 0x00, 0xF4, 0x00, 0x00, 0x1D, 0x00, 0x32, 0x28])
        #expect(RecordCodec.decode(record, format: .standard) == .keys(macro))
    }

    @Test func standardMediaAndMouse() throws {
        let media = try RecordCodec.standard(.media(.webBack), recordID: 1, layer: 0)
        #expect(media[3] == 2 && media[5] == 2 && media[8] == 0x24 && media[11] == 0x02)
        #expect(RecordCodec.decode(media, format: .standard) == .media(.webBack))
        let mouse = try RecordCodec.standard(.mouse(.controlWheelUp), recordID: 1, layer: 0)
        #expect(mouse[3] == 3 && mouse[4] == 1 && mouse[5] == 4 && mouse[8] == 0xF1 && mouse[11] == 0 && mouse[20] == 0x01)
        #expect(RecordCodec.decode(mouse, format: .standard) == .mouse(.controlWheelUp))
        var gesture = mouse
        gesture[4] = 4
        #expect(RecordCodec.decode(gesture, format: .standard) == nil)
    }

    @Test func legacyPairsAndTheWait() throws {
        let macro = KeyMacro([KeyStroke(modifiers: .control, key: 0x06), KeyStroke(key: 0x19)], delay: 500)
        let record = try RecordCodec.encode(.keys(macro), recordID: 16, layer: 0, format: .legacy)
        #expect(record.count == 50)
        #expect(Array(record[0..<14]) == [0xFD, 16, 1, 5, 0xF4, 0x01, 0, 0, 0, 2, 0x01, 0x06, 0x00, 0x19])
        #expect(RecordCodec.decode(record, format: .legacy) == .keys(macro))
        let plain = try RecordCodec.encode(.keys(KeyMacro([KeyStroke(key: 0x04)])), recordID: 1, layer: 0, format: .legacy)
        #expect(plain[3] == 1)
    }

    @Test func legacyMediaAndMouse() throws {
        let media = try RecordCodec.encode(.media(.mute), recordID: 1, layer: 0, format: .legacy)
        #expect(media[3] == 2 && media[9] == 2 && media[10] == 0xE2 && media[11] == 0)
        #expect(RecordCodec.decode(media, format: .legacy) == .media(.mute))
        let wheel = try RecordCodec.encode(.mouse(.optionWheelDown), recordID: 1, layer: 0, format: .legacy)
        #expect(wheel[3] == 3 && wheel[9] == 1 && wheel[10] == 0x04 && wheel[11] == 0 && wheel[14] == 0xFF)
        #expect(RecordCodec.decode(wheel, format: .legacy) == .mouse(.optionWheelDown))
    }

    @Test func modifiersAloneSitAfterTheLastPair() throws {
        let alone = KeyAction.keys(KeyMacro([KeyStroke(modifiers: .option, key: 0)]))
        let record = try RecordCodec.encode(alone, recordID: 1, layer: 0, format: .legacy)
        #expect(record[9] == 0 && record[10] == 0x04 && record[11] == 0)
        #expect(RecordCodec.decode(record, format: .legacy) == alone)
        let standard = try RecordCodec.standard(alone, recordID: 1, layer: 0)
        #expect(standard[5] == 1 && standard[8] == 0xF3)
        #expect(RecordCodec.decode(standard, format: .standard) == alone)
    }

    /// The form keyboards of the 1189:8840 kind take: as the legacy pairs, marked `FE`, a media key with a
    /// count of 0 and a wheel move with 3.
    @Test func unidentifiedRecords() throws {
        let keys = try RecordCodec.unidentified(.keys(KeyMacro([KeyStroke(modifiers: .command, key: 0x06)])), recordID: 17, layer: 0)
        #expect(Array(keys[0..<12]) == [0xFE, 17, 1, 1, 0, 0, 0, 0, 0, 1, 0x08, 0x06])
        let media = try RecordCodec.unidentified(.media(.volumeUp), recordID: 1, layer: 1)
        #expect(Array(media[0..<12]) == [0xFE, 1, 2, 2, 0, 0, 0, 0, 0, 0, 0xE9, 0x00])
        let wheel = try RecordCodec.unidentified(.mouse(.wheelUp), recordID: 1, layer: 0)
        #expect(Array(wheel[0..<15]) == [0xFE, 1, 1, 3, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0x01])
        let click = try RecordCodec.unidentified(.mouse(.leftClick), recordID: 1, layer: 0)
        #expect(Array(click[0..<12]) == [0xFE, 1, 1, 3, 0, 0, 0, 0, 0, 1, 0, 0x01])
    }

    @Test func cleared() throws {
        let record = try RecordCodec.standard(.unassigned, recordID: 2, layer: 0)
        #expect(Array(record[0..<6]) == [0xFD, 2, 1, 1, 0, 0])
        #expect(RecordCodec.decode(record, format: .standard) == .unassigned)
        #expect(RecordCodec.decode([0xFD, 2, 1, 0], format: .legacy) == .unassigned)
        #expect(RecordCodec.decode([0xFD, 2, 1, 9], format: .legacy) == nil)
    }

    @Test func legacyLighting() {
        let record = RecordCodec.legacyLighting(color: .blue, mode: 3, layer: 2)
        #expect(Array(record[0..<12]) == [0xFE, 0xB0, 3, 8, 0, 0, 0, 0, 0, 1, 0, 0x63])
    }

    @Test func answers() {
        #expect(K884xCommands.identity(from: [0x03, 0xFB, 6, 1, 10]) == KeyboardIdentity(keyCount: 6, knobCount: 1, type: 10))
        #expect(K884xCommands.identity(from: [0x03, 0xFB]) == nil)
        let reply: [UInt8] = [0x03, 0xB0, 4] + Array(repeating: 9, count: 48)
        #expect(K884xCommands.lighting(from: reply) == .perKey(mode: 4, colors: Array(repeating: KeyColor(red: 9, green: 9, blue: 9), count: 16)))
        #expect(K884xCommands.readRecords(layer: 0, format: .standard) == [0xFA, 25, 0, 1])
        #expect(K884xCommands.readRecords(layer: 2, format: .legacy) == [0xFA, 0x0F, 0x03, 3])
        #expect(K884xCommands.readReplyCount(.standard) == 25)
        #expect(K884xCommands.readReplyCount(.legacy) == 24)
        #expect(K884xCommands.readRecords(layer: 0, format: .unidentified) == nil)
    }

    @Test func framing() {
        #expect(ReportFraming(reportID: 3, length: 9).frame([0xAA, 0xAA]) == [3, 0xAA, 0xAA, 0, 0, 0, 0, 0, 0])
        #expect(ReportFraming(reportID: 0, length: 8).frame([0xAA]) == [0xAA, 0, 0, 0, 0, 0, 0, 0])
        #expect(ReportFraming(reportID: 3, length: 65).frame(K884xCommands.identify).count == 65)
    }
}

struct WritePlanTests {
    static let layout = KeyboardLayout.named("6add1")!

    static func configuration(_ edit: (inout KeyboardConfiguration) -> Void) -> KeyboardConfiguration {
        var configuration = KeyboardConfiguration(layerCount: 3)
        edit(&configuration)
        return configuration
    }

    /// Every changed record, then all three layers' lights, then one commit (`Widget::HID_write`).
    @Test func standard() throws {
        let configuration = Self.configuration {
            $0.set(.media(.mute), for: .key(number: 2), layer: 1)
            $0.set(.unassigned, for: .knob(number: 1, part: .press), layer: 0)
            for layer in 0..<3 { $0.applyRead(lighting: .perKey(mode: 0, colors: KeyColor.defaultKeyColors), layer: layer) }
            $0.setLighting(.perKey(mode: 2, colors: KeyColor.defaultKeyColors), layer: 2)
        }
        let plan = try WritePlan(configuration, commands: .records(.standard), layout: Self.layout)
        #expect(plan.steps.map { Array($0.payload.prefix(3)) } == [
            [0xFD, 17, 1], [0xFD, 2, 2], [0xFE, 0xB0, 0], [0xFE, 0xB0, 1], [0xFE, 0xB0, 2], [0xFD, 0xFE, 0xFF],
        ])
        #expect(plan.steps.last?.pauseAfter == .milliseconds(200))
        #expect(plan.steps[4].payload[3] == 2)
    }

    /// Lights alone are written without a commit, as the app does.
    @Test func standardLightsAlone() throws {
        let configuration = Self.configuration {
            $0.setLighting(.perKey(mode: 1, colors: KeyColor.defaultKeyColors), layer: 0)
        }
        let plan = try WritePlan(configuration, commands: .records(.standard), layout: Self.layout)
        #expect(plan.steps.map { Array($0.payload.prefix(3)) } == [[0xFE, 0xB0, 0]])
    }

    /// Each layer's records and lights, then that layer's commit.
    @Test func legacy() throws {
        let configuration = Self.configuration {
            $0.set(.media(.mute), for: .key(number: 1), layer: 0)
            $0.setLighting(.colorMode(color: .green, mode: 1), layer: 0)
            $0.set(.media(.mute), for: .key(number: 6), layer: 2)
        }
        let plan = try WritePlan(configuration, commands: .records(.legacy), layout: Self.layout)
        #expect(plan.steps.map { Array($0.payload.prefix(3)) } == [
            [0xFD, 1, 1], [0xFE, 0xB0, 1], [0xFD, 0xFE, 0xFF], [0xFD, 6, 3], [0xFD, 0xFE, 0xFF],
        ])
    }

    @Test func unidentified() throws {
        let configuration = Self.configuration {
            $0.set(.media(.mute), for: .knob(number: 1, part: .rotateRight), layer: 0)
            $0.setLighting(.colorMode(color: .red, mode: 2), layer: 1)
        }
        let plan = try WritePlan(configuration, commands: .records(.unidentified), layout: Self.layout)
        #expect(plan.steps.map(\.payload) == [
            try RecordCodec.unidentified(.media(.mute), recordID: 18, layer: 0),
            [0xAA, 0xAA], [0xFD, 0xFE, 0xFF], [0xAA, 0xAA],
            [0xFB, 0xFB, 0xFB, 0x01], [0xFA, 0x0F, 0x03, 1, 0x7F], [0xFA, 0x0F, 0x03, 2, 0x7F], [0xFA, 0x0F, 0x03, 3, 0x7F],
            [0xFE, 0xB0, 2, 8, 0, 0, 0, 0, 0, 1, 0, 0x12], [0xFD, 0xFE, 0xFF],
        ])
    }

    /// One key at a time on the 8890, knobs numbered from 13.
    @Test func k8890() throws {
        let configuration = Self.configuration {
            $0.set(.keys(KeyMacro([KeyStroke(key: 0x04)])), for: .knob(number: 1, part: .rotateRight), layer: 0)
            $0.setLighting(.mode(1), layer: 0)
        }
        let plan = try WritePlan(configuration, commands: .packets(reportID: 3), layout: Self.layout)
        #expect(plan.steps.map(\.payload) == [
            [0xA1, 1, 0, 0, 0, 0, 0, 0], [0xB0, 0x18, 1, 0, 0, 0, 0, 0], [0xAA, 0xA1, 0, 0, 0, 0, 0, 0],
            [0xA1, 1, 0, 0, 0, 0, 0, 0], [0xAA, 0xAA, 0, 0, 0, 0, 0, 0],
            [0xA1, 1, 0, 0, 0, 0, 0, 0], [15, 0x11, 1, 0, 0, 0, 0, 0], [15, 0x11, 1, 1, 0, 0x04, 0, 0], [0xAA, 0xAA, 0, 0, 0, 0, 0, 0],
        ])
    }

    /// What the app doesn't know is never written.
    @Test func onlyChanges() throws {
        let configuration = Self.configuration { $0.applyRead([.key(number: 1): .media(.mute)], layer: 0) }
        #expect(try WritePlan(configuration, commands: .records(.standard), layout: Self.layout).steps.isEmpty)
    }
}

/// Where each control is stored: the 8890's numbers, and the records of the cross-platform app's layouts.
struct NumberingTests {
    @Test func k8890Numbers() {
        #expect(K8890Numbering.number(of: .key(number: 1)) == 1)
        #expect(K8890Numbering.number(of: .key(number: 12)) == 12)
        #expect(K8890Numbering.number(of: .key(number: 13)) == nil)
        #expect(K8890Numbering.number(of: .knob(number: 1, part: .rotateLeft)) == 13)
        #expect(K8890Numbering.number(of: .knob(number: 1, part: .press)) == 14)
        #expect(K8890Numbering.number(of: .knob(number: 2, part: .rotateRight)) == 18)
        #expect(K8890Numbering.number(of: .knob(number: 3, part: .press)) == nil)
        #expect(K8890Numbering.number(of: .knob(number: 1, part: .pressRotateLeft)) == nil)
    }

    /// Whatever the domain lets the 8890 take has a number.
    @Test func everyAddressableControlHasANumber() {
        let capabilities = KeyboardCapabilities(commands: .packets(reportID: 3))
        let controls = (1...16).map { ControlID.key(number: $0) }
            + (1...3).flatMap { knob in KnobPart.allCases.map { ControlID.knob(number: knob, part: $0) } }
        for control in controls {
            #expect(capabilities.canAddress(control) == (K8890Numbering.number(of: control) != nil), "\(control)")
        }
    }

    /// Every control of every layout has a record of its own, from 1 to 25.
    @Test func everyControlHasARecord() {
        for layout in KeyboardLayout.all {
            let records = layout.controls.compactMap { RecordNumbers.record(of: $0, in: layout) }
            #expect(records.count == layout.controls.count, "\(layout.id)")
            #expect(Set(records).count == records.count, "\(layout.id)")
            #expect(records.allSatisfy { (1...25).contains($0) }, "\(layout.id)")
            for control in layout.controls {
                #expect(RecordNumbers.control(inRecord: RecordNumbers.record(of: control, in: layout)!, of: layout) == control)
            }
        }
        let dial = KeyboardLayout.named("0add1")!
        #expect(RecordNumbers.record(of: .knob(number: 1, part: .pressRotateLeft), in: dial) == 19)
        #expect(RecordNumbers.record(of: .knob(number: 1, part: .pressRotateRight), in: dial) == 21)
        #expect(RecordNumbers.record(of: .knob(number: 4, part: .press), in: KeyboardLayout.named("12add4")!) == 14)
        #expect(RecordNumbers.record(of: .key(number: 7), in: KeyboardLayout.named("6add1")!) == nil)
    }
}
