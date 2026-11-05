import Foundation

/// Which way the app reads: the way its language is written — Arabic right to left, the others left to right.
enum InterfaceDirection {
    /// Tells AppKit, before the first window. By itself AppKit takes the direction from the language macOS is in, so
    /// Arabic chosen in the app would stay left to right, and English chosen on an Arabic Mac would turn round.
    static func apply() {
        var arguments = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        arguments["AppleTextDirection"] = Locale.interfaceIsRightToLeft
        UserDefaults.standard.setVolatileDomain(arguments, forName: UserDefaults.argumentDomain)
    }
}
