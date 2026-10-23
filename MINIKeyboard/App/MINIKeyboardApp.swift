import AppKit
import SwiftUI
import Presentation

@main
struct MINIKeyboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var container = AppContainer()
    @AppStorage(AppearanceMode.userDefaultsKey) private var appearance = AppearanceMode.system

    var body: some Scene {
        let editor = container.editor
        Window(AppDisplayName.current, id: "main") {
            ContentView()
                .environment(editor)
                .preferredColorScheme(appearance.colorScheme)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(replacing: .appInfo) {
                AboutMenuItem()
            }
            // Settings… and right under it Check for Updates…, in one group. The window is the app's
            // own rather than a `Settings` scene: that scene adds its own Settings… item, which no
            // command group can move or replace (macOS 27).
            CommandGroup(replacing: .appSettings) {
                SettingsMenuItem()
                CheckForUpdatesButton()
            }
            KeyboardCommands(editor: editor)
            CommandGroup(after: .windowList) {
                DeviceLogMenuItem()
            }
            #if DEBUG
            CommandMenu(Text("Simulator")) {
                SimulatorMenu(editor: editor)
            }
            #endif
        }

        Window(Text("Device Log"), id: DeviceLogMenuItem.windowID) {
            DeviceLogView()
                .environment(container.deviceLog)
                .preferredColorScheme(appearance.colorScheme)
        }
        .defaultSize(width: 760, height: 420)

        Window(Text("Settings"), id: PreferenceView.windowID) {
            PreferenceView()
                .preferredColorScheme(appearance.colorScheme)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        // Not listed in the Window menu — Settings… opens it.
        .commandsRemoved()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Updates.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

/// The app menu's About item opens Settings ▸ About, which has the icon and the version and more.
/// The pane is chosen before Settings opens, so it shows whether or not the window is open already.
private struct AboutMenuItem: View {
    @Environment(\.openWindow) private var openWindow
    @AppStorage(PreferenceView.tabSelectionKey) private var selection = ""

    var body: some View {
        Button("About \(AppDisplayName.current)") {
            selection = PreferenceTab.about.rawValue
            openWindow(id: PreferenceView.windowID)
        }
    }
}

/// Settings… — the app menu's own, with the standard ⌘, and no picture, as macOS's own item reads.
private struct SettingsMenuItem: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Settings…") { openWindow(id: PreferenceView.windowID) }
            .keyboardShortcut(",", modifiers: .command)
    }
}

/// The Keyboard menu: reading, saving, clearing and the layout.
private struct KeyboardCommands: Commands {
    let editor: KeyboardEditorViewModel

    var body: some Commands {
        CommandMenu("Keyboard") {
            Button("Read from Keyboard") { Task { await editor.read() } }
                .keyboardShortcut("r")
                .disabled(!editor.canRead)
            Button("Save to Keyboard") { Task { await editor.save() } }
                .keyboardShortcut("s")
                .disabled(!editor.isReady)
            Divider()
            // ⌘⌫ rather than a bare ⌫, which would take Delete away from the delay fields.
            Button("Clear Key") { editor.clearSelected() }
                .keyboardShortcut(.delete)
                .disabled(!editor.isReady || editor.selectedControl == nil)
            Button("Clear Layer") { editor.clearLayer() }
                .keyboardShortcut(.delete, modifiers: [.command, .shift])
                .disabled(!editor.isReady)
            Divider()
            Button("Shape…") { editor.isChoosingLayout = true }
                .disabled(!editor.hasLayout)
            Button("Rotate") { editor.rotate() }
                .keyboardShortcut("t")
                .disabled(!editor.hasLayout)
        }
    }
}

private struct DeviceLogMenuItem: View {
    static let windowID = "device-log"
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Device Log") { openWindow(id: Self.windowID) }
            .keyboardShortcut("l", modifiers: [.command, .option])
    }
}
