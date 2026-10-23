import SwiftUI

/// Light, dark or the system's, for the app's windows. Switching is live.
enum AppearanceMode: String, CaseIterable {
    case system, light, dark

    static let userDefaultsKey = "appearanceMode"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct AppearancePicker: View {
    @AppStorage(AppearanceMode.userDefaultsKey) private var mode = AppearanceMode.system

    var body: some View {
        Picker("Appearance", selection: $mode) {
            Text("Follow System").tag(AppearanceMode.system)
            Text("Light").tag(AppearanceMode.light)
            Text("Dark").tag(AppearanceMode.dark)
        }
    }
}
