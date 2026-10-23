#if DEBUG
import SwiftUI
import Presentation

/// Debug builds: the keyboard on USB, or a simulated one of every kind.
struct SimulatorMenu: View {
    let editor: KeyboardEditorViewModel

    var body: some View {
        let choices = editor.simulatorChoices
        Toggle(isOn: binding(nil)) { Text("Keyboard on USB") }
        Divider()
        Menu {
            toggles(choices, .k8890)
        } label: { Text(verbatim: "1189:8890") }
        Menu {
            toggles(choices, .standard)
        } label: { KeyboardInfo.Commands.standard.text }
        Menu {
            toggles(choices, .legacy)
        } label: { KeyboardInfo.Commands.legacy.text }
        toggles(choices, .unidentified)
    }

    private func toggles(_ choices: [SimulatorChoice], _ group: SimulatorChoice.Group) -> some View {
        ForEach(choices.filter { $0.group == group }) { choice in
            Toggle(isOn: binding(choice.id)) { choice.kind.title }
        }
    }

    private func binding(_ id: String?) -> Binding<Bool> {
        Binding(get: { editor.activeSimulatorID == id },
                set: { on in if on { Task { await editor.selectSimulator(id) } } })
    }
}
#endif
