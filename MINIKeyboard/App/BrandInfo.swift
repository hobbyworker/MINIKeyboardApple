import Foundation

/// The values that say whose app this is. They come from the build settings (Signing.xcconfig ▸
/// BRAND_*) through Info.plist; the source carries none. Each may be empty, and the UI leaves out
/// whatever depends on a missing one.
enum BrandInfo {
    /// The Sparkle feed. Empty in a build without updates.
    static var feedURL: String { string("SUFeedURL") }
    /// The key Sparkle checks every update against.
    static var feedPublicKey: String { string("SUPublicEDKey") }
    /// Updates are on only with both: without the key Sparkle can't verify what it downloads.
    static var hasUpdates: Bool { updatesConfigured(feedURL: feedURL, publicKey: feedPublicKey) }
    /// The line under Settings ▸ About. Empty when the build shows none.
    static var copyright: String { string("BrandCopyright") }

    static func updatesConfigured(feedURL: String, publicKey: String) -> Bool {
        !feedURL.isEmpty && !publicKey.isEmpty
    }

    private static func string(_ key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String)?
            .trimmingCharacters(in: .whitespaces) ?? ""
    }
}
