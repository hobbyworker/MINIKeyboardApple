import SwiftUI
import Presentation

/// The main window: the keyboard on top, what to give the selected key below.
struct ContentView: View {
    @Environment(KeyboardEditorViewModel.self) private var editor

    var body: some View {
        @Bindable var editor = editor
        VStack(spacing: 0) {
            HeaderBar()
            if editor.activeSimulatorID != nil {
                SimulatorBar()
            } else {
                Divider()
            }
            KeyboardCanvas()
                .frame(minHeight: 230, idealHeight: 300, maxHeight: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(Color(nsColor: .underPageBackgroundColor))
                .overlay(alignment: .bottomTrailing) { LayoutButtons().padding(10) }
                .layoutPriority(1)
            Divider()
            HStack(alignment: .top, spacing: 0) {
                ActionPanel()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                Divider()
                Inspector()
                    .frame(width: 270)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .frame(minHeight: 360, idealHeight: 380, maxHeight: 520)
        }
        .frame(minWidth: 1000, minHeight: 700)
        .overlay(alignment: .top) {
            NoticeView()
                .padding(.top, 60)
                .animation(.snappy, value: editor.notice)
        }
        // Only with a keyboard to choose for — an empty sheet has no way out.
        .sheet(isPresented: Binding(get: { editor.isChoosingLayout && editor.hasLayout },
                                    set: { editor.isChoosingLayout = $0 })) {
            LayoutSheet()
        }
        // A switch that would drop changes not saved asks first. Only the buttons answer: the alert closing must not
        // forget the switch before Switch makes it.
        .alert(Text("Switch Keyboards?"),
               isPresented: Binding(get: { editor.pendingSwitch != nil }, set: { _ in })) {
            Button("Switch", role: .destructive) { Task { await editor.confirmSwitch() } }
            Button("Cancel", role: .cancel) { editor.cancelSwitch() }
        } message: {
            Text("Changes you haven’t saved will be lost.")
        }
    }
}

/// While a simulated keyboard is in use, a bar across the window says so, loudly — nothing saved then reaches a
/// keyboard — with the way back to the keyboard on USB.
private struct SimulatorBar: View {
    @Environment(KeyboardEditorViewModel.self) private var editor

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Simulator in use")
                    .font(.headline.weight(.heavy))
                Text("This isn't a real keyboard. Nothing you save here is written to any keyboard.")
            }
            .foregroundStyle(.white)
            Spacer(minLength: 12)
            Button("Back to the Keyboard on USB") {
                Task { await editor.selectSimulator(nil) }
            }
            .disabled(!editor.canSwitchKeyboard)
        }
        .padding(.leading, 20)
        .padding(.trailing, 16)
        .padding(.vertical, 10)
        .background(Color.simulator)
    }
}

extension Color {
    /// The simulator's colour: the bar across the window, the keyboard's outline and badge, the header's dot.
    static let simulator = Color(red: 0xC2 / 255, green: 0x41 / 255, blue: 0x0C / 255)
}

/// Rotation and the layout sheet, over the keyboard's corner.
private struct LayoutButtons: View {
    @Environment(KeyboardEditorViewModel.self) private var editor

    var body: some View {
        if editor.hasLayout {
            HStack(spacing: 6) {
                Button {
                    editor.rotate()
                } label: {
                    Label("Rotate", systemImage: "rotate.right")
                }
                .help(Text("Rotate"))
                Button("Shape…") { editor.isChoosingLayout = true }
            }
            .controlSize(.small)
        }
    }
}

/// A message that comes and goes, at the top of the window.
struct NoticeView: View {
    @Environment(KeyboardEditorViewModel.self) private var editor

    var body: some View {
        if let notice = editor.notice {
            HStack(spacing: 8) {
                Image(systemName: notice.isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(notice.isError ? Color.orange : Color.green)
                Text(notice.message)
                Button {
                    editor.dismissNotice()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text("Close"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.regularMaterial, in: Capsule())
            .shadow(radius: 6, y: 2)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
