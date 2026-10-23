import SwiftUI
import Presentation

/// Sets the shape of a keyboard that can't say it, and how the keyboard is turned. It comes up on its own the
/// first time such a keyboard is plugged in — then without Cancel, there being nothing to go back to.
///
/// - A 884x keyboard picks one of the cross-platform app's layouts.
/// - The 1189:8890, which that app doesn't know and whose own tool draws no shape, is arranged: how many keys,
///   how many to a row, how many knobs.
/// - A keyboard that said its shape only turns.
struct LayoutSheet: View {
    @Environment(KeyboardEditorViewModel.self) private var editor
    @State private var layoutID: String?
    @State private var quarterTurns = 0
    @State private var keys = 0
    @State private var columns = 1
    @State private var knobs = 0

    var body: some View {
        if let sheet = editor.layoutSheet {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Choose the Keyboard’s Shape")
                            .font(.title2.weight(.semibold))
                        Spacer()
                        Text(verbatim: sheet.usb)
                            .font(.callout.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    Group {
                        if let reportedKeys = sheet.reportedKeys, let reportedKnobs = sheet.reportedKnobs {
                            Text("The keyboard reports its keys and knobs: \(Text("Keys: \(reportedKeys) · Knobs: \(reportedKnobs)"))")
                        } else {
                            Text("The keyboard doesn’t say how many keys and knobs it has.")
                        }
                        if case .arrangement = sheet.mode {
                            Text("Its real shape isn’t known either. Set how many keys and knobs it has and how many keys are in a row, then rotate it to match how it sits in front of you.")
                        } else {
                            Text("Pick the shape that matches the keyboard, then rotate it to match how it sits in front of you.")
                        }
                    }
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }

                switch sheet.mode {
                case .arrangement(_, _, _, let maxKeys, let maxKnobs):
                    HStack(alignment: .top, spacing: 20) {
                        previewBox(sheet)
                        arrangement(maxKeys: maxKeys, maxKnobs: maxKnobs)
                            .frame(width: 200)
                    }
                    .frame(height: 220)
                case .catalog(let choices, let selectedID):
                    catalog(choices, selectedID: layoutID ?? selectedID)
                    previewBox(sheet).frame(height: 220)
                case .fixed:
                    previewBox(sheet).frame(height: 220)
                }

                HStack {
                    Button {
                        quarterTurns = (quarterTurns + 1) % 4
                    } label: {
                        Label("Rotate", systemImage: "rotate.right")
                    }
                    Spacer()
                    if !sheet.isRequired {
                        Button("Cancel") { editor.isChoosingLayout = false }
                            .keyboardShortcut(.cancelAction)
                    }
                    Button("Done") { done(sheet) }
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(20)
            .frame(width: 680)
            .interactiveDismissDisabled(sheet.isRequired)
            .onAppear {
                quarterTurns = sheet.quarterTurns
                if case .arrangement(let keys, let columns, let knobs, _, _) = sheet.mode {
                    self.keys = keys
                    self.columns = columns
                    self.knobs = knobs
                }
            }
        }
    }

    /// The shape as chosen so far, turned as it sits.
    private func previewBox(_ sheet: LayoutSheetState) -> some View {
        Group {
            if let preview = preview(sheet) {
                ShapeThumbnail(drawing: preview)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(0.05)))
    }

    private func preview(_ sheet: LayoutSheetState) -> ShapeDrawing? {
        switch sheet.mode {
        case .arrangement:
            editor.previewDrawing(keys: keys, columns: min(columns, max(keys, 1)), knobs: knobs, quarterTurns: quarterTurns)
        case .catalog(_, let selectedID):
            editor.previewDrawing(layoutID: layoutID ?? selectedID, quarterTurns: quarterTurns)
        case .fixed:
            editor.previewDrawing(layoutID: nil, quarterTurns: quarterTurns)
        }
    }

    private func done(_ sheet: LayoutSheetState) {
        switch sheet.mode {
        case .arrangement:
            editor.chooseArrangement(keys: keys, columns: min(columns, max(keys, 1)), knobs: knobs, quarterTurns: quarterTurns)
        case .catalog(_, let selectedID):
            editor.chooseLayout(layoutID ?? selectedID, quarterTurns: quarterTurns)
        case .fixed:
            editor.chooseLayout(nil, quarterTurns: quarterTurns)
        }
    }

    /// How many keys, how many to a row, how many knobs. A keyboard has at least one of either: taking the
    /// last one away brings one of the other.
    private func arrangement(maxKeys: Int, maxKnobs: Int) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            CountSlider(title: "Keys", value: $keys, range: 0...maxKeys)
            // A row of one key is all there is to set with fewer than two keys.
            CountSlider(title: "Keys per row", value: $columns, range: 1...max(keys, 2))
                .disabled(keys < 2)
            VStack(alignment: .leading, spacing: 6) {
                Text("Knobs").foregroundStyle(.secondary)
                Picker("Knobs", selection: $knobs) {
                    ForEach(0...maxKnobs, id: \.self) { count in
                        Text(verbatim: "\(count)").tag(count)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }
        }
        .onChange(of: keys) {
            columns = min(columns, max(keys, 1))
            if keys == 0, knobs == 0 { knobs = 1 }
        }
        .onChange(of: knobs) {
            if knobs == 0, keys == 0 { keys = 1 }
        }
    }

    /// The cross-platform app's layouts, each drawn small.
    private func catalog(_ choices: [LayoutChoice], selectedID: String) -> some View {
        ScrollViewReader { scroller in
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                    ForEach(choices) { choice in
                        Button {
                            layoutID = choice.id
                        } label: {
                            VStack(spacing: 6) {
                                ShapeThumbnail(drawing: choice.drawing).frame(height: 52)
                                Text(verbatim: "\(choice.keys) + \(choice.knobs)")
                                    .font(.caption.monospacedDigit())
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(KeyCapStyle(isActive: selectedID == choice.id, minHeight: 80))
                        .accessibilityLabel(Text("Keys: \(choice.keys) · Knobs: \(choice.knobs)"))
                        .id(choice.id)
                    }
                }
                .padding(2)
            }
            .frame(height: 220)
            .onAppear { scroller.scrollTo(selectedID, anchor: .center) }
        }
    }
}

/// A whole number on a slider that stops at each one, with the number beside its name.
private struct CountSlider: View {
    let title: LocalizedStringKey
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).foregroundStyle(.secondary)
                Spacer()
                Text(verbatim: "\(value)").font(.body.monospacedDigit().weight(.medium))
            }
            Slider(value: Binding(get: { Double(value) }, set: { value = Int($0.rounded()) }),
                   in: Double(range.lowerBound)...Double(range.upperBound), step: 1) {
                Text(title)
            }
            .labelsHidden()
        }
    }
}
