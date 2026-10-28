import SwiftUI
import Presentation

/// The keyboard on USB, or a simulated one: the kinds users have, and in a debug build every kind (the 8890's
/// other report IDs, the legacy records). Not while the keyboard is being identified, read or saved.
struct SimulatorMenu: View {
    let editor: KeyboardEditorViewModel

    var body: some View {
        #if DEBUG
        let choices = editor.simulatorChoices
        #else
        let choices = editor.simulatorChoices.filter(\.isForEveryone)
        #endif
        Group {
            Toggle(isOn: binding(nil)) { Text("Keyboard on USB") }
            Divider()
            group(choices, .k8890) { Text(verbatim: "1189:8890") }
            group(choices, .standard) { KeyboardInfo.Commands.standard.text }
            group(choices, .legacy) { KeyboardInfo.Commands.legacy.text }
            toggles(choices.filter { $0.group == .unidentified })
        }
        .disabled(!editor.canSwitchKeyboard)
    }

    /// A group of one is an item of its own, under the group's name; an empty one isn't there.
    @ViewBuilder
    private func group(_ choices: [SimulatorChoice], _ group: SimulatorChoice.Group,
                       @ViewBuilder title: () -> some View) -> some View {
        let members = choices.filter { $0.group == group }
        if members.count == 1, let only = members.first {
            Toggle(isOn: binding(only.id)) { title() }
        } else if !members.isEmpty {
            Menu { toggles(members) } label: { title() }
        }
    }

    private func toggles(_ choices: [SimulatorChoice]) -> some View {
        ForEach(choices) { choice in
            Toggle(isOn: binding(choice.id)) { choice.kind.title }
        }
    }

    private func binding(_ id: String?) -> Binding<Bool> {
        Binding(get: { editor.activeSimulatorID == id },
                set: { on in if on { Task { await editor.selectSimulator(id) } } })
    }
}
