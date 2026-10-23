import Testing
@testable import Domain

struct KeyboardFamilyTests {
    @Test func supportedKeyboards() {
        #expect(KeyboardFamily(usb: USBIdentity(vendorID: 0x1189, productID: 0x8890)) == .k8890)
        #expect(KeyboardFamily(usb: USBIdentity(vendorID: 0x1189, productID: 0x8840)) == .k884x)
        #expect(KeyboardFamily(usb: USBIdentity(vendorID: 0x514C, productID: 0x8851)) == .k884x)
        // The cross-platform app looks for 8851 under 514C only.
        #expect(KeyboardFamily(usb: USBIdentity(vendorID: 0x1189, productID: 0x8851)) == nil)
        #expect(KeyboardFamily(usb: USBIdentity(vendorID: 0x05AC, productID: 0x8890)) == nil)
        #expect(KeyboardFamily.supported.count == 16)
    }

    @Test func usbIdentityPrintsAsHex() {
        #expect("\(USBIdentity(vendorID: 0x514C, productID: 0x8850))" == "514C:8850")
    }

    @Test func identityPicksTheRecordFormat() {
        #expect(KeyboardIdentity(keyCount: 6, knobCount: 1, type: 10).recordFormat == .standard)
        #expect(KeyboardIdentity(keyCount: 6, knobCount: 1, type: 0).recordFormat == .legacy)
        #expect(KeyboardIdentity(keyCount: 6, knobCount: 1, type: 1).recordFormat == .legacy)
    }
}

struct CapabilitiesTests {
    let k8890 = KeyboardCapabilities(commands: .packets(reportID: 3))
    let standard = KeyboardCapabilities(commands: .records(.standard))
    let legacy = KeyboardCapabilities(commands: .records(.legacy))
    let unidentified = KeyboardCapabilities(commands: .records(.unidentified))

    @Test func layers() {
        #expect(k8890.layerCount == 3)
        #expect(KeyboardCapabilities(commands: .packets(reportID: 0)).layerCount == 1)
        #expect(standard.layerCount == 3)
    }

    /// The standard format spends a place on every modifier; the others put a key's modifiers with it.
    @Test func pressesCountModifiersOnTheStandardFormat() {
        let macro = KeyMacro([KeyStroke(modifiers: [.command, .shift], key: 0x1D), KeyStroke(key: 0x04)])
        #expect(standard.presses(in: macro) == 4)
        #expect(legacy.presses(in: macro) == 2)
        #expect(k8890.presses(in: macro) == 2)
        let modifiersOnly = KeyMacro([KeyStroke(modifiers: [.control, .option], key: 0)])
        #expect(standard.presses(in: modifiersOnly) == 2)
    }

    @Test func limits() {
        let five = KeyMacro(Array(repeating: KeyStroke(key: 0x04), count: 5))
        let six = KeyMacro(Array(repeating: KeyStroke(key: 0x04), count: 6))
        #expect(k8890.fits(five))
        #expect(!k8890.fits(six))
        #expect(legacy.fits(KeyMacro(Array(repeating: KeyStroke(key: 0x04), count: 20))))
        #expect(!standard.fits(KeyMacro(Array(repeating: KeyStroke(modifiers: .command, key: 0x04), count: 10))))
        #expect(!k8890.fits(KeyMacro([KeyStroke(key: 0x04), KeyStroke(modifiers: .shift, key: 0)])))
    }

    @Test func whatEachKeyboardDoes() {
        #expect(k8890.mediaKeys == MediaKey.basic)
        #expect(standard.mediaKeys.count == 21)
        #expect(k8890.delays == .unavailable)
        #expect(standard.delays == .perPress(0...60000))
        #expect(legacy.delays == .perKey(0...6000))
        #expect(unidentified.delays == .unavailable)
        #expect(k8890.lighting == .modes([0, 1, 2]))
        #expect(standard.lighting == .perKeyColor(modes: 0...5, keys: 16))
        #expect(legacy.lighting == .colorAndMode(modes: 0...5))
        #expect(standard.reading == .onConnect)
        #expect(legacy.reading == .onRequest)
        #expect(k8890.reading == .never)
        #expect(unidentified.reading == .never)
    }

    /// The 8890 numbers twelve keys and two knobs.
    @Test func the8890AddressesSmallLayoutsOnly() throws {
        #expect(k8890.addresses(try #require(KeyboardLayout.named("6add1"))))
        #expect(k8890.addresses(try #require(KeyboardLayout.named("12add2"))))
        #expect(!k8890.addresses(try #require(KeyboardLayout.named("15add3"))))
        #expect(!k8890.addresses(try #require(KeyboardLayout.named("4add3"))))
        #expect(!k8890.addresses(try #require(KeyboardLayout.named("0add1"))))
        #expect(unidentified.addresses(try #require(KeyboardLayout.named("21add1"))))
    }

    /// The keys each vendor tool offers: 95 on the Windows tool, 110 on the cross-platform app.
    @Test func keysEachKeyboardIsGiven() {
        let usages = (0...0xFF).map(UInt8.init)
        #expect(usages.filter(k8890.takes).count == 95)
        #expect(usages.filter(standard.takes).count == 110)
        #expect(usages.filter(unidentified.takes) == usages.filter(legacy.takes))
        for usage: UInt8 in [0x32, 0x58, 0x64, 0x68, 0x73] {
            #expect(!k8890.takes(key: usage) && standard.takes(key: usage))
        }
        #expect(k8890.takes(key: 0x65) && !k8890.takes(key: 0x66) && !standard.takes(key: 0x66) && !standard.takes(key: 0x74))
        #expect(k8890.takesKeys(of: KeyMacro([KeyStroke(modifiers: .shift, key: 0)])))
        #expect(!k8890.takesKeys(of: KeyMacro([KeyStroke(key: 0x04), KeyStroke(key: 0x68)])))
    }

    /// The 8890 has twelve keys and two knobs that turn and press.
    @Test func whatThe8890Takes() {
        #expect(k8890.canAddress(.key(number: 12)))
        #expect(!k8890.canAddress(.key(number: 13)))
        #expect(k8890.canAddress(.knob(number: 2, part: .rotateRight)))
        #expect(!k8890.canAddress(.knob(number: 3, part: .press)))
        #expect(!k8890.canAddress(.knob(number: 1, part: .pressRotateLeft)))
        #expect(standard.canAddress(.knob(number: 1, part: .pressRotateLeft)))
    }
}
