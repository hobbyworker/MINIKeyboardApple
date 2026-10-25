import SwiftUI

/// The Settings window: a sidebar with the everyday panes on top, a divider, then About.
struct PreferenceView: View {
    /// In UserDefaults, so the app menu's About item can choose the About pane before it opens
    /// Settings.
    static let tabSelectionKey = "preferenceTab"

    /// The settings window's scene — the app menu's Settings… and About open it.
    static let windowID = "settings"

    @AppStorage(Self.tabSelectionKey) private var selectionRaw = ""

    /// A stored pane that isn't listed — never chosen, removed, or General in a build without
    /// updates — falls back to the first one.
    private var selection: Binding<String> {
        Binding(
            get: {
                let listed = PreferenceTab.primary + PreferenceTab.secondary
                return listed.contains { $0.rawValue == selectionRaw } ? selectionRaw : listed[0].rawValue
            },
            set: { selectionRaw = $0 })
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detail
        }
        .frame(width: 700, height: 520)
    }

    private var sidebar: some View {
        List(selection: selection) {
            ForEach(PreferenceTab.primary) { tab in
                PreferenceLabel(tab: tab).tag(tab.rawValue)
            }
            // A row without a tag can't be selected.
            Divider()
            ForEach(PreferenceTab.secondary) { tab in
                PreferenceLabel(tab: tab).tag(tab.rawValue)
            }
        }
        .listStyle(.sidebar)
        .frame(width: 200)
    }

    @ViewBuilder private var detail: some View {
        switch PreferenceTab(rawValue: selection.wrappedValue) ?? .ui {
        case .general: GeneralPane()
        case .ui: UIPane()
        case .about: AboutPane()
        }
    }
}

/// Settings ▸ General: how the app itself behaves — what it sends a keyboard, and (in a build with updates)
/// the update check.
private struct GeneralPane: View {
    var body: some View {
        Form {
            Section {
                LightingKeyRepeatToggle()
            } header: {
                Text("Firmware Workarounds")
            } footer: {
                Text("After its lighting is saved, the 1189:8890 keyboard repeats a key's first stroke without end when the key is pressed (its maker's software does the same). With this on, the app sends one more save after the lighting to stop that; the keys stay as they were. Off, the app sends just what the maker's software sends.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if Updates.isAvailable {
                Section {
                    AutomaticUpdatesToggle()
                } header: {
                    Text("App")
                }
            }
        }
        .formStyle(.grouped)
    }
}
