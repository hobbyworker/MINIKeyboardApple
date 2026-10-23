import SwiftUI
import Presentation

/// The selected key or knob action: what it does, and clearing it.
struct Inspector: View {
    @Environment(KeyboardEditorViewModel.self) private var editor

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let selection = editor.selectionState {
                selected(selection)
            } else {
                Text("Select a key or knob.")
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            HStack {
                Button("Clear") { editor.clearSelected() }
                    .disabled(!editor.isReady || editor.selectedControl == nil)
                Button("Clear Layer") { editor.clearLayer() }
                    .disabled(!editor.isReady)
            }
            unsavedState
        }
        .padding(16)
    }

    private func selected(_ selection: SelectionState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            selection.title.text
                .font(.title3.weight(.semibold))
            if let layer = selection.layerNumber {
                Text("Layer \(layer)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Divider()
            switch selection.binding {
            case .unknown:
                Text("Not known — this keyboard doesn’t tell what its keys do. Whatever you set here is written when you save.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            case .nothing:
                Text("Nothing").foregroundStyle(.secondary)
            case .presses(let strokes, let keyDelay, let used, let limit):
                presses(strokes, keyDelay: keyDelay, used: used, limit: limit)
            case .media(let key):
                Label { Text(key.title) } icon: { Image(systemName: key.systemImage) }
                    .font(.title3)
            case .otherMedia(let usage):
                ActionCaption.otherMedia(usage).text.font(.title3)
            case .mouse(let mouse):
                Label { Text(mouse.title) } icon: { Image(systemName: mouse.systemImage) }
                    .font(.title3)
            }
            if let held = editor.heldModifierText {
                Text("Next key with \(held)")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            }
        }
    }

    private func presses(_ strokes: [String], keyDelay: Int, used: Int, limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FlowLayout(spacing: 4) {
                ForEach(Array(strokes.enumerated()), id: \.offset) { _, stroke in
                    Text(verbatim: stroke)
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.primary.opacity(0.08)))
                }
            }
            .textSelection(.enabled)
            if keyDelay > 0 {
                Text("Waits \(keyDelay) ms").font(.caption).foregroundStyle(.secondary)
            }
            Text("\(used) of \(limit) presses")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                editor.removeLastStroke()
            } label: {
                Label("Remove Last Press", systemImage: "delete.backward")
            }
            .controlSize(.small)
            .disabled(strokes.isEmpty)
        }
    }

    @ViewBuilder private var unsavedState: some View {
        if editor.hasUnsavedChanges {
            Label("Unsaved changes", systemImage: "circle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
        } else if editor.isReady {
            Label("No unsaved changes", systemImage: "checkmark.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
