import SwiftUI
import Presentation

/// The shown layer's lights, in what the keyboard takes.
struct LightingPageView: View {
    @Environment(KeyboardEditorViewModel.self) private var editor

    var body: some View {
        switch editor.lightingPage {
        case .modes(let modes, let active)?:
            ModesLighting(modes: modes, active: active)
        case .colorAndMode(let colors, let modes, let activeColor, let activeMode)?:
            ColorAndModeLighting(colors: colors, modes: modes, activeColor: activeColor, activeMode: activeMode)
        case .perKeyColor(let modes, let activeMode, let keys, let selected)?:
            PerKeyLighting(modes: modes, activeMode: activeMode, keys: keys, selected: selected)
        case nil:
            EmptyView()
        }
    }
}

/// The 1189:8890's modes. What a mode is set to isn't known until the user sets it — the keyboard can't
/// be asked.
private struct ModesLighting: View {
    @Environment(KeyboardEditorViewModel.self) private var editor
    let modes: [Int]
    let active: Int?

    var body: some View {
        PanelSection(title: "LED", note: "Lighting is set per layer; no key selection is needed.") {
            HStack(alignment: .top, spacing: 10) {
                ForEach(modes, id: \.self) { mode in
                    Button {
                        editor.setLightingMode(mode)
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: LightingModeNames.systemImage(mode)).font(.system(size: 18))
                            Text(LightingModeNames.title(mode, k8890: true)).font(.system(size: 13, weight: .semibold))
                            if let detail = LightingModeNames.detail(mode) {
                                Text(detail).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                    .buttonStyle(KeyCapStyle(isActive: active == mode, minHeight: 96))
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// A colour and a mode for the layer.
private struct ColorAndModeLighting: View {
    @Environment(KeyboardEditorViewModel.self) private var editor
    let colors: [LEDColor]
    let modes: [Int]
    let activeColor: LEDColor?
    let activeMode: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PanelSection(title: "Color") {
                HStack(spacing: 8) {
                    ForEach(colors, id: \.self) { color in
                        Button {
                            editor.setLightColor(color)
                        } label: {
                            HStack(spacing: 6) {
                                Circle().fill(color.color).frame(width: 12, height: 12)
                                Text(color.title)
                            }
                        }
                        .buttonStyle(KeyCapStyle(isActive: activeColor == color))
                        .fixedSize()
                    }
                }
            }
            PanelSection(title: "Effect", note: "Lighting is set per layer; no key selection is needed.") {
                HStack(spacing: 8) {
                    ForEach(modes, id: \.self) { mode in
                        Button {
                            editor.setLightingMode(mode)
                        } label: {
                            Text(LightingModeNames.title(mode, k8890: false))
                        }
                        .buttonStyle(KeyCapStyle(isActive: activeMode == mode))
                        .frame(width: 90)
                    }
                }
            }
        }
    }
}

/// A mode for the layer and a colour for each of its first keys.
private struct PerKeyLighting: View {
    @Environment(KeyboardEditorViewModel.self) private var editor
    let modes: [Int]
    let activeMode: Int?
    let keys: Int
    let selected: KeyColorSelection?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PanelSection(title: "Effect") {
                HStack(spacing: 8) {
                    ForEach(modes, id: \.self) { mode in
                        Button {
                            editor.setLightingMode(mode)
                        } label: {
                            Text(LightingModeNames.title(mode, k8890: false))
                        }
                        .buttonStyle(KeyCapStyle(isActive: activeMode == mode))
                        .frame(width: 90)
                    }
                }
            }
            PanelSection(title: "Color", note: "Select one of keys 1–\(keys) on the keyboard, then pick its color.") {
                HStack(alignment: .top, spacing: 18) {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(26), spacing: 5), count: 14), alignment: .leading, spacing: 5) {
                        ForEach(Array(RGB.palette.enumerated()), id: \.offset) { _, color in
                            Button {
                                editor.setKeyColor(color)
                            } label: {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(color.color)
                                    .frame(width: 26, height: 26)
                                    .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.primary.opacity(0.2)))
                            }
                            .buttonStyle(.plain)
                            .help(Text(verbatim: color.hex))
                        }
                    }
                    .fixedSize()
                    if let selected {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selected.color.color)
                                .frame(width: 60, height: 60)
                                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.primary.opacity(0.2)))
                            selected.title.text.font(.caption.weight(.semibold))
                            Text(verbatim: selected.color.hex)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

/// Waits: before each press on the standard format, for the whole key on the legacy one.
struct DelayPageView: View {
    @Environment(KeyboardEditorViewModel.self) private var editor

    var body: some View {
        switch editor.delayPage {
        case .perPress(let range, let presses):
            PanelSection(title: "Delay", note: "Each press can wait before it is sent. Give the key its presses on the Keys page first.") {
                if presses.isEmpty {
                    Text("The selected key has no presses.").foregroundStyle(.secondary)
                } else {
                    Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
                        ForEach(presses) { press in
                            GridRow {
                                Text("Press \(press.index + 1)").foregroundStyle(.secondary)
                                Text(verbatim: press.text)
                                    .font(.body.weight(.medium))
                                    .frame(minWidth: 90, alignment: .leading)
                                MillisecondsField(value: press.delay, range: range) {
                                    editor.setDelay(press: press.index, milliseconds: $0)
                                }
                            }
                        }
                    }
                }
            }
        case .perKey(let range, let value):
            PanelSection(title: "Delay", note: "One wait for the whole key. Its presses stay.") {
                if let value {
                    MillisecondsField(value: value, range: range) {
                        editor.setKeyDelay(milliseconds: $0)
                    }
                } else {
                    Text("Select a key or knob.").foregroundStyle(.secondary)
                }
            }
        case .unavailable:
            EmptyView()
        }
    }
}

/// A number of milliseconds, kept in `range`.
private struct MillisecondsField: View {
    let value: Int
    let range: ClosedRange<Int>
    var step = 10
    let commit: (Int) -> Void
    @State private var text = ""

    var body: some View {
        HStack(spacing: 4) {
            TextField("Delay", text: $text)
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
                .onSubmit { apply(Int(text) ?? value) }
            Stepper("Delay", onIncrement: { apply(value + step) }, onDecrement: { apply(value - step) })
                .labelsHidden()
            Text(verbatim: "ms").foregroundStyle(.secondary)
        }
        .fixedSize()
        .onAppear { text = String(value) }
        .onChange(of: value) { text = String(value) }
    }

    private func apply(_ new: Int) {
        let clamped = min(max(new, range.lowerBound), range.upperBound)
        text = String(clamped)
        commit(clamped)
    }
}
