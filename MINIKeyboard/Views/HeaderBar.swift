import SwiftUI
import Presentation

/// The keyboard's state, the layer, and reading and saving.
struct HeaderBar: View {
    @Environment(KeyboardEditorViewModel.self) private var editor

    var body: some View {
        @Bindable var editor = editor
        HStack(spacing: 16) {
            ConnectionStatusView()
            Spacer(minLength: 12)
            if editor.layerCount > 1 {
                Picker("Layer", selection: $editor.layer) {
                    ForEach(0..<editor.layerCount, id: \.self) { layer in
                        Text("Layer \(layer + 1)").tag(layer)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                .disabled(!editor.isReady)
            }
            if editor.readsBack {
                Button {
                    Task { await editor.read() }
                } label: {
                    Label("Read", systemImage: "square.and.arrow.down.on.square")
                }
                .help(Text("Read from Keyboard"))
                .disabled(!editor.canRead)
            }
            Button {
                Task { await editor.save() }
            } label: {
                Label("Save", systemImage: "square.and.arrow.up")
            }
            .help(Text("Save to Keyboard"))
            .buttonStyle(.borderedProminent)
            .disabled(!editor.isReady || !editor.hasUnsavedChanges)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }
}

/// A dot, what the app is doing with the keyboard, and the keyboard's USB ID.
struct ConnectionStatusView: View {
    @Environment(KeyboardEditorViewModel.self) private var editor
    @Environment(\.openURL) private var openURL
    @State private var showsInfo = false

    private static let inputMonitoring =
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                title.font(.headline)
                detail
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            switch editor.status {
            case .connected(_, _, _, let isIdentified, _):
                if let info = editor.keyboardInfo {
                    Button {
                        showsInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .buttonStyle(.borderless)
                    .help(Text("Keyboard Information"))
                    .accessibilityLabel(Text("Keyboard Information"))
                    .popover(isPresented: $showsInfo, arrowEdge: .bottom) {
                        KeyboardInfoView(info: info)
                    }
                }
                if !isIdentified, editor.activity == nil {
                    Button("Retry") { Task { await editor.identify() } }
                }
            case .needsPermission:
                Button("Open Privacy & Security") { openURL(Self.inputMonitoring) }
                Button("Retry") { Task { await editor.retryConnection() } }
            case .openFailed:
                Button("Retry") { Task { await editor.retryConnection() } }
            case .searching:
                EmptyView()
            }
            if editor.activity != nil {
                ProgressView().controlSize(.small)
            }
        }
    }

    private var color: Color {
        switch editor.status {
        case .connected(_, _, _, _, true): .simulator
        case .connected(_, _, _, let isIdentified, _): isIdentified ? .green : .yellow
        case .needsPermission: .orange
        case .searching, .openFailed: .red
        }
    }

    @ViewBuilder private var title: some View {
        switch editor.status {
        case .searching:
            Text("Not Connected")
        case .needsPermission:
            Text("Input Monitoring is needed")
        case .openFailed:
            Text("The keyboard couldn’t be opened")
        case .connected(_, _, _, _, let isSimulated):
            switch editor.activity {
            case .identifying: Text("Asking the keyboard what it is…")
            case .reading: Text("Reading…")
            case .saving: Text("Saving…")
            case nil where isSimulated: Text("Simulated Keyboard")
            case nil: Text("Connected")
            }
        }
    }

    @ViewBuilder private var detail: some View {
        switch editor.status {
        case .searching:
            Text("Connect the keyboard via USB.")
        case .needsPermission:
            Text("Allow \(AppDisplayName.current) in Privacy & Security ▸ Input Monitoring.")
        case .openFailed(let code):
            Text(verbatim: String(format: "IOReturn 0x%08X", UInt32(bitPattern: code)))
        case .connected(let usb, let keys?, let knobs?, _, _):
            Text("\(usb) · \(Text("Keys: \(keys) · Knobs: \(knobs)"))")
        case .connected(let usb, _, _, _, _):
            Text(verbatim: usb)
        }
    }
}
