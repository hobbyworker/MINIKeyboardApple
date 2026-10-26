import Domain

/// Which of the keyboards plugged in the app opens — the rule, apart from IOKit so tests can hold it.
///
/// The one chosen this session, while it stays plugged in; else the one chosen last time (its USB ID and port),
/// when it is plugged in; else the first, in the order the app looks at keyboards, that can be opened at all.
enum KeyboardChoice {
    /// What "the one chosen last time" is kept as — its USB ID and port, e.g. `1189:8890@01120000`.
    static func key(_ keyboard: AttachedKeyboard) -> String { "\(keyboard.usb)@\(keyboard.location)" }

    /// The keyboard to open. One the user chose (now or last time) is opened even when it can't be, so the failure
    /// is shown rather than passed over for another.
    static func target(
        _ keyboards: [AttachedKeyboard], chosen: AttachedKeyboard.ID?, remembered: String?,
        canOpen: (AttachedKeyboard) -> Bool
    ) -> AttachedKeyboard? {
        if let chosen, let keyboard = keyboards.first(where: { $0.id == chosen }) { return keyboard }
        if let remembered, let keyboard = keyboards.first(where: { key($0) == remembered }) { return keyboard }
        return keyboards.first(where: canOpen) ?? keyboards.first
    }

    /// One entry for each keyboard, in the order its first place to write came — the 1189:8890 first, then the 884x
    /// keyboards in the order the cross-platform app looks for them; several with the same USB ID by port.
    static func ordered(_ found: [AttachedKeyboard]) -> [AttachedKeyboard] {
        var unique: [AttachedKeyboard] = []
        for keyboard in found where !unique.contains(where: { $0.id == keyboard.id }) { unique.append(keyboard) }
        var firstOfUSB: [USBIdentity: Int] = [:]
        for (index, keyboard) in unique.enumerated() where firstOfUSB[keyboard.usb] == nil {
            firstOfUSB[keyboard.usb] = index
        }
        return unique.sorted {
            (firstOfUSB[$0.usb] ?? 0, $0.location) < (firstOfUSB[$1.usb] ?? 0, $1.location)
        }
    }
}
