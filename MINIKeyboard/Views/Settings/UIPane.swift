import SwiftUI

/// Settings ▸ UI: the interface language, and light or dark.
struct UIPane: View {
    var body: some View {
        Form {
            // One section for both. The header names them rather than reaching for a word that
            // covers both — "Display" reads as *monitor*.
            Section {
                LanguagePicker()
                AppearancePicker()
            } header: {
                Text("Language & Appearance")
            } footer: {
                Text("The base language is English. You can follow the system language or choose one yourself.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
