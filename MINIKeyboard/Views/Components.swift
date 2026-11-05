import SwiftUI

extension Locale {
    /// The language the app shows — the catalog's language macOS picked for it ("ar", "ko" …).
    static let interfaceLanguage = Bundle.main.preferredLocalizations.first ?? "en"

    /// Whether the app's language is written right to left — Arabic.
    static let interfaceIsRightToLeft = Locale.Language(identifier: interfaceLanguage).characterDirection == .rightToLeft

    /// Arabic as the app writes it: the digits 0–9 rather than the region's, the user's region otherwise. `nil` in every
    /// other language, where the digits already are 0–9.
    static let westernDigits: Locale? = {
        guard interfaceLanguage.hasPrefix("ar") else { return nil }
        var components = Locale.Components(locale: .current)
        components.languageComponents = Locale.Language.Components(identifier: interfaceLanguage)
        components.numberingSystem = Locale.NumberingSystem("latn")
        return Locale(components: components)
    }()
}

extension String {
    /// Key names and presses as the keys print them, left to right — in Arabic a lone "(" would turn round and "⇧("
    /// read ")⇧". Unchanged in the other languages.
    var leftToRight: String { Locale.interfaceIsRightToLeft ? "\u{2066}\(self)\u{2069}" : self }
}

extension View {
    /// Numbers in Western digits in Arabic (see `Locale.westernDigits`); nothing changes in other languages.
    @ViewBuilder func westernDigits() -> some View {
        if let locale = Locale.westernDigits {
            environment(\.locale, locale)
        } else {
            self
        }
    }
}

/// A key cap in the action pages.
struct KeyCapStyle: ButtonStyle {
    var isActive = false
    var minHeight: CGFloat = 34
    /// Takes the size it is given, however small — a cap on the full-size keyboard.
    var isCompact = false

    func makeBody(configuration: Configuration) -> some View {
        KeyCap(configuration: configuration, isActive: isActive, minHeight: minHeight, isCompact: isCompact)
    }

    private struct KeyCap: View {
        @Environment(\.isEnabled) private var isEnabled
        let configuration: ButtonStyleConfiguration
        let isActive: Bool
        let minHeight: CGFloat
        let isCompact: Bool

        var body: some View {
            configuration.label
                .font(.system(size: isCompact ? 11 : 12, weight: .medium))
                .lineLimit(isCompact ? 1 : 2)
                .minimumScaleFactor(isCompact ? 0.6 : 1)
                .multilineTextAlignment(.center)
                .padding(.horizontal, isCompact ? 2 : 6)
                .frame(minWidth: isCompact ? 0 : 34, maxWidth: .infinity, minHeight: isCompact ? 0 : minHeight,
                       maxHeight: isCompact ? .infinity : nil)
                .foregroundStyle(isActive ? Color.white : Color.primary)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isActive ? Color.accentColor : configuration.isPressed
                            ? Color.accentColor.opacity(0.3) : Color(nsColor: .controlColor)))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(isActive ? Color.accentColor : Color.primary.opacity(0.15)))
                .shadow(color: .black.opacity(configuration.isPressed ? 0 : 0.1), radius: 0.5, y: 1)
                .opacity(isEnabled ? 1 : 0.45)
                .contentShape(Rectangle())
        }
    }
}

/// A titled group of controls in a page.
struct PanelSection<Content: View>: View {
    let title: LocalizedStringKey
    var note: LocalizedStringKey?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content
            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Rows of buttons that wrap.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
