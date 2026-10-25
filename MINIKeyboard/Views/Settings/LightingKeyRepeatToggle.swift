import SwiftUI

/// Settings ▸ General ▸ Keyboard: after the 1189:8890's lighting save, one more save with no key in it, which
/// stops the key repeat that save leaves. The vendor's tool doesn't send it, so it's a setting — on by default.
struct LightingKeyRepeatToggle: View {
    static let userDefaultsKey = "PreventLightingKeyRepeat"

    /// What the next write uses; on until the user turns it off.
    static var isOn: Bool {
        UserDefaults.standard.object(forKey: userDefaultsKey) as? Bool ?? true
    }

    @AppStorage(Self.userDefaultsKey) private var isOn = true

    var body: some View {
        Toggle("Prevent key repeat after changing the lighting", isOn: $isOn)
    }
}
