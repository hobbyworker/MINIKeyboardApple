/// Finding the keyboard and keeping its configuration interface open.
public protocol KeyboardConnectionRepository: Sendable {
    /// The current state, then every change.
    func connectionStates() async -> AsyncStream<ConnectionState>

    /// Looks for the keyboard again — after Input Monitoring was allowed, or another app let go of it.
    func retry() async

    /// The supported keyboards plugged in and the one the app opens, then every change.
    func attachedKeyboards() async -> AsyncStream<AttachedKeyboards>

    /// Opens another of the keyboards plugged in, in place of the one open now, and keeps it for next time.
    func selectKeyboard(_ id: AttachedKeyboard.ID) async
}

extension KeyboardConnectionRepository {
    /// A connection with one keyboard only — a simulated one — has no others to choose from.
    public func attachedKeyboards() async -> AsyncStream<AttachedKeyboards> {
        AsyncStream { continuation in
            continuation.yield(.none)
            continuation.finish()
        }
    }

    public func selectKeyboard(_ id: AttachedKeyboard.ID) async {}
}

/// Talking to the open keyboard.
public protocol KeyboardDeviceRepository: Sendable {
    /// Asks a 884x keyboard who it is (`FB FB FB`) once. Nil when no answer comes in time.
    func askIdentity() async throws(KeyboardDeviceError) -> KeyboardIdentity?

    /// The actions one layer holds, for the controls of `layout` — standard and legacy formats only. Answers that
    /// stop coming after the first end the read with what came; none at all is `noReply`.
    func readActions(layer: Int, format: RecordFormat, layout: KeyboardLayout)
        async throws(KeyboardDeviceError) -> LayerRead

    /// `action` as the keyboard's records of `format` hold it — what reading it back gives. Nil when the records
    /// can't hold it.
    func storedForm(of action: KeyAction, format: RecordFormat) -> KeyAction?

    /// One layer's lights — the standard format only.
    func readLighting(layer: Int) async throws(KeyboardDeviceError) -> LayerLighting

    /// Writes every changed action and light of `configuration`, in the order the keyboard's vendor tool
    /// writes them, and has the keyboard keep them.
    func write(_ configuration: KeyboardConfiguration, commands: CommandSet, layout: KeyboardLayout)
        async throws(KeyboardDeviceError)
}

/// The layouts users chose, by keyboard.
public protocol LayoutProfileRepository: Sendable {
    func profile(for keyboard: USBIdentity) -> LayoutProfile?
    func save(_ profile: LayoutProfile, for keyboard: USBIdentity)
}

/// The reports exchanged with the keyboard, for the device log.
public protocol DeviceLogRepository: Sendable {
    /// The current entries, then the whole list after every change.
    func entries() async -> AsyncStream<[DeviceLogEntry]>

    func clear() async
}

/// Choosing between the keyboard on USB and a simulated one.
public protocol KeyboardSourceRepository: Sendable {
    func current() async -> KeyboardSource
    func select(_ source: KeyboardSource) async
}
