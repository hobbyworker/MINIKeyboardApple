import AppKit
import Testing

@testable import MINIKeyboard

/// The app menu starts with About, then Settings… — and Check for Updates… right under Settings…
/// only in a build with updates. The test host is the app, so this is its real menu.
@MainActor
struct AppMenuTests {
    private var items: [NSMenuItem] { NSApp.mainMenu?.items.first?.submenu?.items ?? [] }

    @Test func aboutThenSettingsThenUpdates() throws {
        let items = items
        let titles = items.map { $0.isSeparatorItem ? "—" : $0.title }
        #expect(items.first?.title == String(localized: "About \(AppDisplayName.current)"), "\(titles)")
        let settings = try #require(items.firstIndex { $0.keyEquivalent == "," && $0.keyEquivalentModifierMask == .command })
        #expect(settings == 2, "\(titles)")
        // One Settings… — a `Settings` scene would add a second one of its own.
        #expect(items.filter { $0.keyEquivalent == "," }.count == 1, "\(titles)")
        #expect(items.filter { $0.title == items[settings].title }.count == 1, "\(titles)")
        #expect(items[settings].image == nil)
        #expect(items[1].isSeparatorItem)
        let next = try #require(items.indices.contains(settings + 1) ? items[settings + 1] : nil)
        if Updates.isAvailable {
            #expect(next.title == String(localized: "Check for Updates…"), "\(titles)")
        } else {
            #expect(next.isSeparatorItem)
        }
    }
}
