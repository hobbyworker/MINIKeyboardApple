import Testing
@testable import DataLayer
import Domain

/// Which of several keyboards plugged in the app opens.
struct KeyboardChoiceTests {
    static let k8890 = USBIdentity(vendorID: 0x1189, productID: 0x8890)
    static let k8840 = USBIdentity(vendorID: 0x1189, productID: 0x8840)

    static func keyboard(_ id: String, _ usb: USBIdentity, at location: String) -> AttachedKeyboard {
        AttachedKeyboard(id: id, usb: usb, location: location)
    }

    /// One entry per keyboard, in the order their places to write came; the same USB ID by port.
    @Test func orderedByFamilyThenPort() {
        let a = Self.keyboard("a", Self.k8890, at: "02100000")
        let b = Self.keyboard("b", Self.k8890, at: "01100000")
        let c = Self.keyboard("c", Self.k8840, at: "00100000")
        #expect(KeyboardChoice.ordered([a, b, c, c]) == [b, a, c])
    }

    @Test func theOneChosenWins() {
        let keyboards = [Self.keyboard("a", Self.k8890, at: "1"), Self.keyboard("b", Self.k8840, at: "2")]
        let target = KeyboardChoice.target(keyboards, chosen: "b", remembered: "1189:8890@1", canOpen: { _ in true })
        #expect(target == keyboards[1])
    }

    /// Nothing chosen this session: the one chosen last time, found by its USB ID and port.
    @Test func thenTheOneChosenLastTime() {
        let keyboards = [Self.keyboard("a", Self.k8890, at: "1"), Self.keyboard("b", Self.k8840, at: "2")]
        let remembered = KeyboardChoice.key(keyboards[1])
        #expect(remembered == "1189:8840@2")
        let target = KeyboardChoice.target(keyboards, chosen: nil, remembered: remembered, canOpen: { _ in true })
        #expect(target == keyboards[1])
    }

    /// Nothing chosen: the first that can be opened — and with none, the first, to show why it can't.
    @Test func elseTheFirstThatOpens() {
        let keyboards = [Self.keyboard("a", Self.k8890, at: "1"), Self.keyboard("b", Self.k8840, at: "2")]
        let gone = "1189:8890@9"
        #expect(KeyboardChoice.target(keyboards, chosen: "x", remembered: gone, canOpen: { $0.id == "b" }) == keyboards[1])
        #expect(KeyboardChoice.target(keyboards, chosen: nil, remembered: nil, canOpen: { _ in false }) == keyboards[0])
        #expect(KeyboardChoice.target([], chosen: nil, remembered: nil, canOpen: { _ in true }) == nil)
    }
}
