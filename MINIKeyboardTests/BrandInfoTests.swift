import Testing

@testable import MINIKeyboard

/// Updates are on only with both the feed and its public key: without the key Sparkle can't verify
/// what it downloads.
struct BrandInfoTests {
    @Test func updatesNeedBothTheFeedAndItsKey() {
        #expect(BrandInfo.updatesConfigured(feedURL: "https://example.com/appcast.xml", publicKey: "key"))
        #expect(!BrandInfo.updatesConfigured(feedURL: "https://example.com/appcast.xml", publicKey: ""))
        #expect(!BrandInfo.updatesConfigured(feedURL: "", publicKey: "key"))
        #expect(!BrandInfo.updatesConfigured(feedURL: "", publicKey: ""))
    }

    /// The menu, General and About all go by this one value.
    @Test func thisBuildFollowsItsOwnValues() {
        #expect(BrandInfo.hasUpdates
            == BrandInfo.updatesConfigured(feedURL: BrandInfo.feedURL, publicKey: BrandInfo.feedPublicKey))
    }
}
