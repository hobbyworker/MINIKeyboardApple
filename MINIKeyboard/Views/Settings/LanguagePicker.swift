import AppKit
import SwiftUI

enum UILanguage {
    static let userDefaultsKey = "uiLanguageOverride"
    static let system = "system"

    /// Each language in its own script — someone looking for theirs recognises it there.
    /// ⚠️ Must match the localizations in the catalog, or the picker offers a language that falls
    /// back to English.
    static let options: [(code: String, name: String)] = [
        ("en", "English"),
        ("ko", "한국어"),
        ("ja", "日本語"),
        ("zh-Hans", "简体中文"),
        ("zh-Hant", "繁體中文"),
        ("es", "Español"),
        ("pt-BR", "Português (Brasil)"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("it", "Italiano"),
        ("pl", "Polski"),
        ("id", "Bahasa Indonesia"),
        ("vi", "Tiếng Việt"),
    ]
}

/// The interface language, chosen in the app. Stored apart from `AppleLanguages`, so "Follow
/// System" differs from "never chose"; a change writes the `AppleLanguages` override, which is
/// read once at launch, and offers a relaunch.
struct LanguagePicker: View {
    @AppStorage(UILanguage.userDefaultsKey) private var choice = UILanguage.system

    var body: some View {
        Picker("Language", selection: $choice) {
            Text("Follow System").tag(UILanguage.system)
            ForEach(UILanguage.options, id: \.code) { option in
                Text(verbatim: option.name).tag(option.code)
            }
        }
        .onChange(of: choice) { _, code in
            // Once the picker has finished updating — the alert blocks.
            Task { apply(code) }
        }
    }

    private func apply(_ code: String) {
        if code == UILanguage.system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        }

        let alert = NSAlert()
        alert.messageText = String(localized: "Language Changed")
        alert.informativeText = String(localized: "\(AppDisplayName.current) needs to relaunch to apply the change.")
        alert.addButton(withTitle: String(localized: "Relaunch Now"))
        alert.addButton(withTitle: String(localized: "Later"))
        if alert.runModal() == .alertFirstButtonReturn {
            AppRelauncher.relaunch()
        }
    }
}
