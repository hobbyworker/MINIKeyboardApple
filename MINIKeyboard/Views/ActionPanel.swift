import SwiftUI
import Presentation

/// The pages of actions for the selected key.
struct ActionPanel: View {
    @Environment(KeyboardEditorViewModel.self) private var editor

    var body: some View {
        @Bindable var editor = editor
        VStack(alignment: .leading, spacing: 12) {
            Picker("Action", selection: $editor.tab) {
                ForEach(editor.availableTabs) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .disabled(!editor.isReady)
            // The pages are disabled, not the scroll view: macOS hides a disabled scroll view's scroller, and a scroller
            // that is always shown takes room, so the keys would grow and shrink around every read and save.
            ScrollView(.vertical) {
                Group {
                    switch editor.tab {
                    case .keys: KeysPage()
                    case .media: MediaPage()
                    case .mouse: MousePage()
                    case .lighting: LightingPageView()
                    case .delay: DelayPageView()
                    }
                }
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .disabled(!editor.isReady)
            }
        }
        .padding(16)
    }
}

/// Modifiers to hold, then a key: each key pressed is added to the selected key's presses. The keys are laid
/// out as on a full-size keyboard or in groups, as the user picks — until then, as the keyboard's vendor tool
/// does — and only the keys the keyboard is given can be pressed.
private struct KeysPage: View {
    @Environment(KeyboardEditorViewModel.self) private var editor
    /// Empty until the user picks one.
    @AppStorage("keyArrangement") private var storedArrangement = ""

    private var arrangement: Binding<KeyArrangement> {
        Binding(
            get: { KeyArrangement(rawValue: storedArrangement) ?? editor.vendorKeyArrangement },
            set: { storedArrangement = $0.rawValue })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Picker("Key Layout", selection: arrangement) {
                        Text(verbatim: "QWERTY").tag(KeyArrangement.qwerty)
                        Text(verbatim: "ABC").tag(KeyArrangement.alphabetical)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                    Spacer()
                    Button("Modifiers Only") { editor.assignHeldModifiers() }
                        .buttonStyle(KeyCapStyle(minHeight: 26))
                        .fixedSize()
                        .disabled(editor.heldModifiers.isEmpty)
                        .help(Text("Makes the key hold these modifiers, as a modifier key does."))
                }
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            switch arrangement.wrappedValue {
            case .qwerty: FullKeyboardKeys()
            case .alphabetical: GroupedKeys()
            }
        }
    }

    private var note: LocalizedStringKey {
        guard editor.pressLimit > 0 else { return "Modifiers apply to the next key." }
        return editor.modifiersCountAsPresses
            ? "Modifiers apply to the next key. A key holds up to \(editor.pressLimit) presses, each modifier counting as one."
            : "Modifiers apply to the next key. A key holds up to \(editor.pressLimit) presses."
    }
}

/// The keys as on a full-size keyboard, whose modifier keys are held for the next key. A key the keyboard
/// isn't given stays in its place, off.
private struct FullKeyboardKeys: View {
    @Environment(KeyboardEditorViewModel.self) private var editor

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            BoardLayout(columns: BoardCap.rowWidth) {
                ForEach(editor.keyBoard) { cap in
                    capButton(cap)
                        .layoutValue(key: BoardPlace.self, value: BoardPlace.Value(row: cap.row, column: cap.column, width: cap.width))
                }
            }
            let more = editor.moreKeys
            if !more.isEmpty {
                PanelSection(title: "More Keys") {
                    FlowLayout(spacing: 4) {
                        ForEach(more) { KeyButton(key: $0) }
                    }
                }
            }
        }
    }

    @ViewBuilder private func capButton(_ cap: BoardCap) -> some View {
        switch cap.face {
        case .key(let key):
            Button {
                editor.press(key)
            } label: {
                KeyLabel(key: key)
            }
            .buttonStyle(KeyCapStyle(isCompact: true))
            .disabled(!cap.isEnabled)
            .help(cap.isEnabled ? key.name : Text("This keyboard doesn’t take this key."))
        case .modifier(let modifier):
            Button {
                editor.toggle(modifier)
            } label: {
                Text(verbatim: modifier.symbol)
            }
            .buttonStyle(KeyCapStyle(isActive: editor.heldModifiers.contains(modifier), isCompact: true))
            .help(Text(modifier.title))
            .accessibilityLabel(Text(modifier.title))
        }
    }
}

/// The keys in groups, the letters in alphabetical order, under a row of modifiers to hold.
private struct GroupedKeys: View {
    @Environment(KeyboardEditorViewModel.self) private var editor

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PanelSection(title: "Modifiers") {
                HStack(spacing: 6) {
                    ForEach(ModifierKey.allCases, id: \.self) { modifier in
                        Button {
                            editor.toggle(modifier)
                        } label: {
                            Text(verbatim: modifier.symbol).font(.system(size: 14, weight: .medium))
                        }
                        .buttonStyle(KeyCapStyle(isActive: editor.heldModifiers.contains(modifier)))
                        .frame(width: 46)
                        .help(Text(modifier.title))
                        .accessibilityLabel(Text(modifier.title))
                    }
                }
            }
            ForEach(editor.keyGroups) { group in
                PanelSection(title: group.kind.title) {
                    FlowLayout(spacing: 4) {
                        ForEach(group.keys) { KeyButton(key: $0) }
                    }
                }
            }
            PanelSection(title: "Shift Symbols") {
                FlowLayout(spacing: 4) {
                    ForEach(editor.shiftSymbols) { key in
                        if let shifted = key.shifted {
                            Button(shifted) { editor.press(shifted: key) }
                                .buttonStyle(KeyCapStyle())
                                .frame(minWidth: 38)
                                .fixedSize()
                                .help(Text(verbatim: "⇧\(key.label)"))
                        }
                    }
                }
            }
        }
    }
}

/// A key to press, at its own size.
private struct KeyButton: View {
    @Environment(KeyboardEditorViewModel.self) private var editor
    let key: KeyUsage

    var body: some View {
        Button {
            editor.press(key)
        } label: {
            KeyLabel(key: key)
        }
        .buttonStyle(KeyCapStyle())
        .frame(minWidth: 38)
        .fixedSize()
        .help(key.name)
    }
}

/// A key cap's face: the key, and above it the character it makes with Shift.
private struct KeyLabel: View {
    let key: KeyUsage

    var body: some View {
        VStack(spacing: 0) {
            if let shifted = key.shifted {
                Text(verbatim: shifted).font(.system(size: 9)).foregroundStyle(.secondary)
            }
            Text(verbatim: key.label)
        }
    }
}

/// Caps placed by their row and column in key widths. A key is as wide as the width offered allows, up to
/// `maxUnit`; a cap two keys wide also spans the gap between them.
private struct BoardLayout: Layout {
    let columns: Double
    var spacing: CGFloat = 3
    var maxUnit: CGFloat = 40

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let unit = unit(for: proposal.width ?? .infinity)
        let rows = CGFloat((subviews.map { $0[BoardPlace.self].row }.max() ?? -1) + 1)
        return CGSize(width: unit * columns + spacing * (columns - 1), height: rows * unit + max(rows - 1, 0) * spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let unit = unit(for: bounds.width)
        for subview in subviews {
            let place = subview[BoardPlace.self]
            let origin = CGPoint(x: bounds.minX + place.column * (unit + spacing), y: bounds.minY + CGFloat(place.row) * (unit + spacing))
            subview.place(at: origin, proposal: ProposedViewSize(width: unit * place.width + spacing * (place.width - 1), height: unit))
        }
    }

    private func unit(for width: CGFloat) -> CGFloat {
        min(maxUnit, (width - spacing * (columns - 1)) / columns)
    }
}

private struct BoardPlace: LayoutValueKey {
    struct Value {
        var row = 0
        var column = 0.0
        var width = 1.0
    }

    static let defaultValue = Value()
}

private struct MediaPage: View {
    @Environment(KeyboardEditorViewModel.self) private var editor

    var body: some View {
        PanelSection(title: "Multimedia", note: "A media key replaces what the key did.") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(editor.mediaChoices, id: \.self) { key in
                    Button {
                        editor.assign(key)
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: key.systemImage).font(.system(size: 15))
                            Text(key.title)
                        }
                    }
                    .buttonStyle(KeyCapStyle(isActive: editor.selectedCaption == .media(key), minHeight: 52))
                }
            }
        }
    }
}

private struct MousePage: View {
    @Environment(KeyboardEditorViewModel.self) private var editor

    var body: some View {
        PanelSection(title: "Mouse", note: "A mouse action replaces what the key did.") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(MouseChoice.allCases, id: \.self) { action in
                    Button {
                        editor.assign(action)
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: action.systemImage).font(.system(size: 15))
                            Text(action.title)
                        }
                    }
                    .buttonStyle(KeyCapStyle(isActive: editor.selectedCaption == .mouse(action), minHeight: 52))
                }
            }
        }
    }
}
