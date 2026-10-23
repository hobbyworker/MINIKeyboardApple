import Testing
@testable import Domain

struct LayoutTests {
    @Test func everyLayoutIsConsistent() {
        #expect(KeyboardLayout.all.count == 26)
        #expect(Set(KeyboardLayout.all.map(\.id)).count == 26)
        for layout in KeyboardLayout.all {
            #expect(Set(layout.controls).count == layout.controls.count, "\(layout.id)")
            let keys = layout.controls.compactMap { control -> Int? in
                if case .key(let number) = control { return number }
                return nil
            }
            #expect(keys == Array(1..<(keys.count + 1)), "\(layout.id)")
            #expect(Set(layout.controls.compactMap(\.knobNumber)) == Set(1..<(layout.knobCount + 1)), "\(layout.id)")
        }
    }

    /// `Widget::Identify_KeyBoard_style`.
    @Test func identifiedLayouts() {
        func id(_ keys: Int, _ knobs: Int, type: Int = 10, product: Int = 0x8840) -> String {
            KeyboardLayout.identifiedID(for: KeyboardIdentity(keyCount: keys, knobCount: knobs, type: type), productID: product)
        }
        #expect(id(6, 1) == "6add1")
        #expect(id(0, 2) == "0add1")
        #expect(id(0, 2, product: 0x8850) == "0add2")
        #expect(id(4, 1, type: 0) == "4add1")
        #expect(id(4, 1, type: 0, product: 0x8851) == "4add2")
        #expect(id(4, 1, type: 1) == "4add2")
        #expect(id(4, 1, type: 10) == "15add3")
        #expect(id(7, 7) == "15add3")
        for layout in KeyboardLayout.all where layout.id != "15add3" {
            #expect(KeyboardLayout.named(layout.id) != nil)
        }
    }

    /// One knob that also turns while pressed — not two knobs.
    @Test func theDialHasOneKnob() throws {
        let dial = try #require(KeyboardLayout.named("0add1"))
        #expect(dial.knobCount == 1)
        #expect(dial.controls.contains(.knob(number: 1, part: .pressRotateLeft)))
        #expect(dial.controls.contains(.knob(number: 1, part: .pressRotateRight)))
        #expect(try #require(KeyboardLayout.named("0add2")).knobCount == 2)
    }

    @Test func rotationTurnsAround() {
        #expect(Rotation.threeQuarters.next == .upright)
        #expect(Rotation.upright.next == .quarter)
    }
}

struct ResolveLayoutTests {
    final class Profiles: LayoutProfileRepository, @unchecked Sendable {
        var saved: [USBIdentity: LayoutProfile] = [:]
        func profile(for keyboard: USBIdentity) -> LayoutProfile? { saved[keyboard] }
        func save(_ profile: LayoutProfile, for keyboard: USBIdentity) { saved[keyboard] = profile }
    }

    static func keyboard(_ product: Int, family: KeyboardFamily) -> ConnectedKeyboard {
        ConnectedKeyboard(
            usb: USBIdentity(vendorID: 0x1189, productID: product), family: family, interfaceNumber: 0, channel: .hid,
            reportID: 3, reportLength: 65, details: nil)
    }

    @Test func anIdentifiedKeyboardGetsItsLayout() {
        let profiles = Profiles()
        let identification = KeyboardIdentification(
            commands: .records(.standard), identity: KeyboardIdentity(keyCount: 9, knobCount: 2, type: 10))
        let resolved = ResolveLayoutUseCase(profiles: profiles).execute(Self.keyboard(0x8840, family: .k884x), identification: identification)
        #expect(resolved.layout.id == "9add2")
        #expect(resolved.source == .identified)
        #expect(resolved.choices.isEmpty)
        #expect(!resolved.needsChoice)
    }

    /// The cross-platform app doesn't know the 8890 and its own tool draws no shape, so the user arranges it.
    /// Until then it is drawn as the tool's twelve keys, four to a row, and two knobs.
    @Test func the8890IsArranged() throws {
        let profiles = Profiles()
        let keyboard = Self.keyboard(0x8890, family: .k8890)
        let identification = KeyboardIdentification(commands: .packets(reportID: 3), identity: nil)
        let resolved = ResolveLayoutUseCase(profiles: profiles).execute(keyboard, identification: identification)
        #expect(resolved.layout.id == "grid-12-4-2")
        #expect(resolved.needsChoice)
        #expect(resolved.choices.isEmpty)
        #expect(resolved.grid == .k8890)

        let sixAndOne = try #require(GridShape(keys: 6, columns: 3, knobs: 1)).layout
        let chosen = ChooseLayoutUseCase(profiles: profiles).execute(resolved, layout: sixAndOne, rotation: .half, for: keyboard.usb)
        #expect(chosen.layout == sixAndOne)
        #expect(chosen.rotation == .half)
        #expect(chosen.source == .chosen)

        let again = ResolveLayoutUseCase(profiles: profiles).execute(keyboard, identification: identification)
        #expect(again.layout == sixAndOne)
        #expect(again.rotation == .half)
        #expect(!again.needsChoice)

        // Neither an arrangement it can't number nor one of the cross-platform app's layouts.
        let tooBig = try #require(GridShape(keys: 13, columns: 4, knobs: 0)).layout
        #expect(ChooseLayoutUseCase(profiles: profiles).execute(again, layout: tooBig, rotation: .upright, for: keyboard.usb).layout == sixAndOne)
        let appLayout = try #require(KeyboardLayout.named("6add1"))
        #expect(ChooseLayoutUseCase(profiles: profiles).execute(again, layout: appLayout, rotation: .upright, for: keyboard.usb).layout == sixAndOne)
    }

    @Test func anUnidentifiedKeyboardMayHaveAnyLayout() {
        let resolved = ResolveLayoutUseCase(profiles: Profiles()).execute(
            Self.keyboard(0x8840, family: .k884x), identification: KeyboardIdentification(commands: .records(.unidentified), identity: nil))
        #expect(resolved.choices.count == 26)
        #expect(resolved.layout.id == "15add3")
        #expect(resolved.needsChoice)
    }

    /// The layout of a keyboard that said its shape stays; only the rotation is kept.
    @Test func anIdentifiedLayoutOnlyTurns() throws {
        let profiles = Profiles()
        let keyboard = Self.keyboard(0x8840, family: .k884x)
        let identification = KeyboardIdentification(
            commands: .records(.legacy), identity: KeyboardIdentity(keyCount: 6, knobCount: 1, type: 0))
        let resolved = ResolveLayoutUseCase(profiles: profiles).execute(keyboard, identification: identification)
        let other = try #require(KeyboardLayout.named("12add0"))
        let chosen = ChooseLayoutUseCase(profiles: profiles).execute(resolved, layout: other, rotation: .quarter, for: keyboard.usb)
        #expect(chosen.layout.id == "6add1")
        #expect(chosen.rotation == .quarter)
        #expect(ResolveLayoutUseCase(profiles: profiles).execute(keyboard, identification: identification).rotation == .quarter)
    }
}

struct GridShapeTests {
    @Test func ids() throws {
        let shape = try #require(GridShape(keys: 6, columns: 3, knobs: 1))
        #expect(shape.id == "grid-6-3-1")
        #expect(GridShape(id: "grid-6-3-1") == shape)
        #expect(GridShape(id: "6add1") == nil)
        #expect(GridShape(keys: 0, columns: 1, knobs: 0) == nil)
        #expect(GridShape(keys: 6, columns: 7, knobs: 0) == nil)
        #expect(GridShape(keys: 0, columns: 1, knobs: 2) != nil)
        #expect(try #require(GridShape(keys: 7, columns: 3, knobs: 0)).rows == 3)
    }

    /// Keys first, numbered from 1, then each knob's three actions.
    @Test func controls() throws {
        let layout = try #require(GridShape(keys: 7, columns: 3, knobs: 2)).layout
        #expect(layout.controls.prefix(7) == (1...7).map { ControlID.key(number: $0) }[...])
        #expect(layout.controls.suffix(3) == [.knob(number: 2, part: .rotateLeft), .knob(number: 2, part: .press), .knob(number: 2, part: .rotateRight)][...])
        #expect(layout.keyCount == 7 && layout.knobCount == 2)
        #expect(KeyboardCapabilities(commands: .packets(reportID: 3)).addresses(layout))
        #expect(!KeyboardCapabilities(commands: .packets(reportID: 3)).addresses(GridShape(keys: 13, columns: 4, knobs: 0)!.layout))
    }
}
