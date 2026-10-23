import Foundation
import Domain

/// The layouts users chose, in the user defaults under "LayoutProfile.<USB ID>".
/// `@unchecked Sendable`: `UserDefaults` is thread-safe and this type holds nothing else.
public final class UserDefaultsLayoutProfiles: LayoutProfileRepository, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func profile(for keyboard: USBIdentity) -> LayoutProfile? {
        guard let data = defaults.data(forKey: Self.key(keyboard)) else { return nil }
        return try? JSONDecoder().decode(LayoutProfile.self, from: data)
    }

    public func save(_ profile: LayoutProfile, for keyboard: USBIdentity) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        defaults.set(data, forKey: Self.key(keyboard))
    }

    private static func key(_ keyboard: USBIdentity) -> String {
        "LayoutProfile.\(keyboard)"
    }
}
