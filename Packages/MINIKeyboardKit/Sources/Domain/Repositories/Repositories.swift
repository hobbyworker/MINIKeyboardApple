/// Finding the keyboard and keeping its configuration interface open.
public protocol KeyboardConnectionRepository: Sendable {
    /// The current state, then every change.
    func connectionStates() async -> AsyncStream<ConnectionState>

    /// Looks for the keyboard again — after Input Monitoring was allowed, or another app let go of it.
    func retry() async
}

/// Talking to the open keyboard.
public protocol KeyboardDeviceRepository: Sendable {
    /// Asks a 884x keyboard who it is (`FB FB FB`) once. Nil when no answer comes in time.
    func askIdentity() async throws(KeyboardDeviceError) -> KeyboardIdentity?

    /// The actions one layer holds, for the controls of `layout` — standard and legacy formats only.
    func readActions(layer: Int, format: RecordFormat, layout: KeyboardLayout)
        async throws(KeyboardDeviceError) -> [ControlID: KeyAction]

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

/// Choosing between the keyboard on USB and a simulated one (debug builds).
public protocol KeyboardSourceRepository: Sendable {
    func current() async -> KeyboardSource
    func select(_ source: KeyboardSource) async
}
