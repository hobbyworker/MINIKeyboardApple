import Foundation

/// The version as the user sees it, read from the bundle.
enum AppVersion {
    /// `MARKETING_VERSION`.
    static var marketing: String { string("CFBundleShortVersionString") }
    /// `CURRENT_PROJECT_VERSION`.
    static var build: String { string("CFBundleVersion") }

    private static func string(_ key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "—"
    }
}
