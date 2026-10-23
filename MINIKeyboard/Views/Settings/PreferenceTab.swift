import SwiftUI

/// The Settings panes, with their names, pictures and colors.
enum PreferenceTab: String, CaseIterable, Identifiable {
    case general, ui, about

    var id: String { rawValue }

    /// The everyday panes, above a divider. General holds only the automatic update check, so a
    /// build without updates leaves it out.
    @MainActor static var primary: [PreferenceTab] {
        Updates.isAvailable ? [.general, .ui] : [.ui]
    }
    static let secondary: [PreferenceTab] = [.about]

    var title: LocalizedStringKey {
        switch self {
        case .general: "General"
        case .ui: "UI"
        case .about: "About"
        }
    }

    fileprivate var systemImage: String {
        switch self {
        case .general: "gearshape.fill"
        case .ui: "paintbrush.fill"
        case .about: "info"
        }
    }

    fileprivate var color: Color {
        switch self {
        case .general: .blue
        case .ui: .pink
        case .about: .gray
        }
    }
}

/// A pane's name beside its picture on a colored tile.
struct PreferenceLabel: View {
    let tab: PreferenceTab

    var body: some View {
        Label {
            Text(tab.title)
        } icon: {
            Image(systemName: tab.systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(RoundedRectangle(cornerRadius: 5).fill(tab.color.gradient))
        }
    }
}
