import SwiftUI
import Presentation

/// The main window: the keyboard on top, what to give the selected key below.
struct ContentView: View {
    @Environment(KeyboardEditorViewModel.self) private var editor

    var body: some View {
        @Bindable var editor = editor
        VStack(spacing: 0) {
            HeaderBar()
            Divider()
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
        .sheet(isPresented: $editor.isChoosingLayout) {
            LayoutSheet()
        }
    }
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
