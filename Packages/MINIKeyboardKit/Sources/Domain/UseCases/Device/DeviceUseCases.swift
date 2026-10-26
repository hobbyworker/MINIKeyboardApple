/// Follows the keyboard as it comes and goes.
public struct ObserveConnectionUseCase: Sendable {
    private let repository: any KeyboardConnectionRepository

    public init(repository: any KeyboardConnectionRepository) {
        self.repository = repository
    }

    public func execute() async -> AsyncStream<ConnectionState> {
        await repository.connectionStates()
    }
}

/// Follows the supported keyboards plugged in and the one the app opens.
public struct ObserveAttachedKeyboardsUseCase: Sendable {
    private let repository: any KeyboardConnectionRepository

    public init(repository: any KeyboardConnectionRepository) {
        self.repository = repository
    }

    public func execute() async -> AsyncStream<AttachedKeyboards> {
        await repository.attachedKeyboards()
    }
}

/// Opens another of the keyboards plugged in.
public struct SelectKeyboardUseCase: Sendable {
    private let repository: any KeyboardConnectionRepository

    public init(repository: any KeyboardConnectionRepository) {
        self.repository = repository
    }

    public func execute(_ id: AttachedKeyboard.ID) async {
        await repository.selectKeyboard(id)
    }
}

/// Looks for the keyboard again.
public struct RetryConnectionUseCase: Sendable {
    private let repository: any KeyboardConnectionRepository

    public init(repository: any KeyboardConnectionRepository) {
        self.repository = repository
    }

    public func execute() async {
        await repository.retry()
    }
}

/// Settles the commands a newly connected keyboard takes. The 8890's report ID is in its descriptor, so it
/// is asked nothing; a 884x keyboard is asked who it is, up to `attempts` times, and one that never
/// answers is written in the `FE` form.
public struct IdentifyKeyboardUseCase: Sendable {
    private let repository: any KeyboardDeviceRepository
    private let attempts: Int

    public init(repository: any KeyboardDeviceRepository, attempts: Int = 3) {
        self.repository = repository
        self.attempts = max(attempts, 1)
    }

    public func execute(_ keyboard: ConnectedKeyboard) async throws(KeyboardDeviceError) -> KeyboardIdentification {
        switch keyboard.family {
        case .k8890:
            return KeyboardIdentification(commands: .packets(reportID: keyboard.reportID), identity: nil)
        case .k884x:
            for _ in 0..<attempts {
                do {
                    if let identity = try await repository.askIdentity() {
                        return KeyboardIdentification(commands: .records(identity.recordFormat), identity: identity)
                    }
                } catch .invalidReply {
                    continue
                }
            }
            return KeyboardIdentification(commands: .records(.unidentified), identity: nil)
        }
    }
}

/// Reads what the keyboard holds into `configuration`: every layer's actions and, on the standard format,
/// every layer's lights. A layer whose answers don't all arrive is left as it was.
public struct ReadKeyboardUseCase: Sendable {
    public struct Outcome: Sendable {
        public let configuration: KeyboardConfiguration
        public let error: KeyboardDeviceError?
    }

    private let repository: any KeyboardDeviceRepository

    public init(repository: any KeyboardDeviceRepository) {
        self.repository = repository
    }

    public func execute(
        _ configuration: KeyboardConfiguration, capabilities: KeyboardCapabilities, layout: KeyboardLayout
    ) async -> Outcome {
        guard case .records(let format) = capabilities.commands, capabilities.reading != .never else {
            return Outcome(configuration: configuration, error: .unsupported)
        }
        var updated = configuration
        do {
            for layer in 0..<updated.layerCount {
                updated.applyRead(try await repository.readActions(layer: layer, format: format, layout: layout), layer: layer)
            }
            if case .perKeyColor = capabilities.lighting {
                for layer in 0..<updated.layerCount {
                    updated.applyRead(lighting: try await repository.readLighting(layer: layer), layer: layer)
                }
            }
        } catch {
            return Outcome(configuration: updated, error: error)
        }
        return Outcome(configuration: updated, error: nil)
    }
}

/// Writes what changed. On a failure the changes stay marked, so saving can be tried again.
public struct SaveKeyboardUseCase: Sendable {
    public enum Outcome: Sendable, Equatable {
        case saved(KeyboardConfiguration)
        case nothingToSave
    }

    private let repository: any KeyboardDeviceRepository

    public init(repository: any KeyboardDeviceRepository) {
        self.repository = repository
    }

    public func execute(
        _ configuration: KeyboardConfiguration, capabilities: KeyboardCapabilities, layout: KeyboardLayout
    ) async throws(KeyboardDeviceError) -> Outcome {
        guard configuration.hasUnsavedChanges else { return .nothingToSave }
        try await repository.write(configuration, commands: capabilities.commands, layout: layout)
        var saved = configuration
        saved.markSaved()
        return .saved(saved)
    }
}

/// The device log.
public struct DeviceLogUseCase: Sendable {
    private let repository: any DeviceLogRepository

    public init(repository: any DeviceLogRepository) {
        self.repository = repository
    }

    public func entries() async -> AsyncStream<[DeviceLogEntry]> {
        await repository.entries()
    }

    public func clear() async {
        await repository.clear()
    }
}

/// Switches between the keyboard on USB and a simulated one.
public struct KeyboardSourceUseCase: Sendable {
    private let repository: any KeyboardSourceRepository

    public init(repository: any KeyboardSourceRepository) {
        self.repository = repository
    }

    public func current() async -> KeyboardSource {
        await repository.current()
    }

    public func select(_ source: KeyboardSource) async {
        await repository.select(source)
    }
}
