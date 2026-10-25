import SwiftUI
import Presentation

/// The connected keyboard as the view model draws it, turned the way it sits. A key shows what it does.
struct KeyboardCanvas: View {
    @Environment(KeyboardEditorViewModel.self) private var editor

    var body: some View {
        if let drawing = editor.drawing {
            ScaledDrawing(frame: drawing.frame, bounds: drawing.bounds, items: drawing.controls, rect: \.rect,
                          simulated: editor.activeSimulatorID != nil) { control, scale in
                ControlButton(control: control, scale: scale)
            }
            .opacity(editor.isReady ? 1 : 0.45)
            .disabled(!editor.isReady)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "keyboard")
                    .font(.system(size: 30))
                    .foregroundStyle(.tertiary)
                Text("Keys appear here once the keyboard is connected.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// A drawing scaled to fit: the keyboard's body, and a view for each item where `rect` puts it. A simulated
/// keyboard's body has an orange outline and a badge on its top edge.
struct ScaledDrawing<Item: Identifiable, Face: View>: View {
    let frame: LayoutRect
    let bounds: LayoutRect
    let items: [Item]
    let rect: KeyPath<Item, LayoutRect>
    var margin: Double = 14
    var simulated = false
    @ViewBuilder let face: (Item, Double) -> Face

    var body: some View {
        GeometryReader { proxy in
            let scale = max(min((proxy.size.width - 2 * margin) / bounds.width,
                                (proxy.size.height - 2 * margin) / bounds.height), 0.01)
            let originX = (proxy.size.width - bounds.width * scale) / 2
            let originY = (proxy.size.height - bounds.height * scale) / 2
            let place = { (rect: LayoutRect) -> CGPoint in
                CGPoint(x: originX + (rect.midX - bounds.x) * scale, y: originY + (rect.midY - bounds.y) * scale)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 24 * scale, style: .continuous)
                    .fill(LinearGradient(colors: [Color(white: 0.28), Color(white: 0.19)], startPoint: .top, endPoint: .bottom))
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
                    .overlay {
                        if simulated {
                            RoundedRectangle(cornerRadius: 24 * scale, style: .continuous)
                                .strokeBorder(Color.simulator, lineWidth: 4)
                        }
                    }
                    .frame(width: frame.width * scale, height: frame.height * scale)
                    .position(place(frame))
                ForEach(items) { item in
                    let itemRect = item[keyPath: rect]
                    face(item, scale)
                        .frame(width: itemRect.width * scale, height: itemRect.height * scale)
                        .position(place(itemRect))
                }
                if simulated {
                    Text("Simulator")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.simulator, in: RoundedRectangle(cornerRadius: 6))
                        .position(x: place(frame).x, y: place(frame).y - frame.height * scale / 2)
                        .allowsHitTesting(false)
                }
            }
        }
    }
}

/// A key or one action of a knob, selectable.
private struct ControlButton: View {
    @Environment(KeyboardEditorViewModel.self) private var editor
    let control: ControlDrawing
    let scale: Double

    var body: some View {
        Button {
            editor.select(control.ref)
        } label: {
            Group {
                switch control.face {
                case .key(let number): keyFace(number: number)
                case .knob(let action): knobFace(action: action)
                }
            }
            .overlay(alignment: .topTrailing) {
                if control.isChanged {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 7, height: 7)
                        .padding(isKey ? 5 : 1)
                }
            }
        }
        .buttonStyle(.plain)
        .help(helpText)
        .accessibilityLabel(control.ref.title.text)
        .shadow(color: control.isSelected ? Color.accentColor.opacity(0.8) : .clear, radius: 6)
    }

    private var isKey: Bool {
        if case .key = control.face { return true }
        return false
    }

    private func keyFace(number: Int) -> some View {
        let corner = 10 * scale
        let led = control.ledColor
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill((led?.color ?? Color(white: 0.42)).gradient)
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .strokeBorder(control.isSelected ? Color.accentColor : Color.white.opacity(0.15),
                              lineWidth: control.isSelected ? 3 : 1)
            Text(verbatim: "\(number)")
                .font(.system(size: max(9, 15 * scale), weight: .semibold, design: .rounded))
                .foregroundStyle(led == nil ? Color(red: 0.4, green: 0.86, blue: 0.4) : .white)
                .shadow(color: .black.opacity(led == nil ? 0 : 0.8), radius: 1.5)
                .padding(.leading, 6 * scale + 2)
                .padding(.top, 4 * scale + 1)
            control.caption.text
                .font(.system(size: max(8, 13 * scale), weight: .medium))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.7), radius: 1)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 3)
                .padding(.top, max(10, 20 * scale))
                .padding(.bottom, 3)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }

    private func knobFace(action: KnobAction) -> some View {
        let symbol = switch action {
        case .rotateLeft: "arrow.counterclockwise"
        case .press: "smallcircle.filled.circle"
        case .rotateRight: "arrow.clockwise"
        case .pressRotateLeft: "arrow.counterclockwise.circle.fill"
        case .pressRotateRight: "arrow.clockwise.circle.fill"
        }
        return ZStack {
            Circle()
                .fill(Color(white: action == .press ? 0.46 : 0.36).gradient)
            Circle()
                .strokeBorder(control.isSelected ? Color.accentColor
                                  : control.caption.isAssigned ? Color.green.opacity(0.75) : Color.white.opacity(0.15),
                              lineWidth: control.isSelected ? 3 : 1.5)
            Image(systemName: symbol)
                .font(.system(size: max(10, control.rect.width * scale * 0.38), weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .contentShape(Circle())
    }

    private var helpText: Text {
        guard control.caption.isAssigned else { return control.ref.title.text }
        return Text("\(control.ref.title.text): \(control.caption.text)")
    }
}

/// A keyboard's shape drawn small, for choosing one.
struct ShapeThumbnail: View {
    let drawing: ShapeDrawing
    var margin: Double = 4

    var body: some View {
        ScaledDrawing(frame: drawing.frame, bounds: drawing.bounds, items: drawing.items, rect: \.rect, margin: margin) { item, scale in
            if item.isKnob {
                Circle().fill(Color(white: 0.55))
            } else {
                RoundedRectangle(cornerRadius: 8 * scale).fill(Color(white: 0.55))
            }
        }
    }
}
