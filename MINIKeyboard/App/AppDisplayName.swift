import Foundation

/// The app's name as the user sees it, read from the bundle — the source never spells it out.
enum AppDisplayName {
    static var current: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? ProcessInfo.processInfo.processName
    }
}
