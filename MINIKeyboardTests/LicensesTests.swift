import Testing

@testable import MINIKeyboard

/// Without the files in `Resources/Licenses/` the sheet is left with a single "not found" line —
/// no error anywhere else.
struct LicensesTests {
    @Test func sparkleLicenseIsBundled() {
        #expect(Licenses.areBundled)
        let markdown = Licenses.markdown
        #expect(markdown.contains("## Sparkle"))
        #expect(markdown.contains("Permission is hereby granted"))
        #expect(markdown.contains("EXTERNAL LICENSES"))
    }
}
