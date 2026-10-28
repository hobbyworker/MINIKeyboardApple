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
/// every layer's lights. Controls whose answers don't come are left as they were, and the read goes on to the
/// next layer; a read that fails stops there.
public struct ReadKeyboardUseCase: Sendable {
    public struct Outcome: Sendable {
        public let configuration: KeyboardConfiguration
        public let error: KeyboardDeviceError?
        /// The controls not read, by layer — only layers that have some.
        public let unread: [Int: Set<ControlID>]
    }

    private let repository: any KeyboardDeviceRepository

    public init(repository: any KeyboardDeviceRepository) {
        self.repository = repository
    }

    public func execute(
        _ configuration: KeyboardConfiguration, capabilities: KeyboardCapabilities, layout: KeyboardLayout
    ) async -> Outcome {
        guard case .records(let format) = capabilities.commands, capabilities.reading != .never else {
            return Outcome(configuration: configuration, error: .unsupported, unread: [:])
        }
        var updated = configuration
        var unread: [Int: Set<ControlID>] = [:]
        do {
            for layer in 0..<updated.layerCount {
                let read = try await repository.readActions(layer: layer, format: format, layout: layout)
                updated.applyRead(read.actions, layer: layer)
                if !read.unread.isEmpty { unread[layer] = read.unread }
            }
            if case .perKeyColor = capabilities.lighting {
                for layer in 0..<updated.layerCount {
                    updated.applyRead(lighting: try await repository.readLighting(layer: layer), layer: layer)
                }
            }
        } catch {
            return Outcome(configuration: updated, error: error, unread: unread)
        }
        return Outcome(configuration: updated, error: nil, unread: unread)
    }
}

/// Writes what changed, then, on a keyboard that reads back, reads the changed layers back to see that it holds
/// what was written. On a failure the changes stay marked, so saving can be tried again — and so do changes that
/// read back otherwise.
public struct SaveKeyboardUseCase: Sendable {
    public enum Outcome: Sendable, Equatable {
        case saved(KeyboardConfiguration, Check)
        case nothingToSave
    }

    /// What reading back after the write found.
    public enum Check: Hashable, Sendable {
        /// The keyboard doesn't read back.
        case notChecked
        /// Everything written that reads back read back as written — legacy lights have no read, and a control in a
        /// record beyond those a read asks for isn't read.
        case matched
        /// These controls, by layer, and these layers' lights read back otherwise.
        case differs(controls: [Int: Set<ControlID>], lighting: Set<Int>)
        /// Nothing read back otherwise, but something written couldn't be compared: a read failed, or a control's
        /// answer didn't come.
        case couldNotCheck
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
        let check = await readBack(configuration, capabilities: capabilities, layout: layout)
        var saved = configuration
        if case .differs(let controls, let lighting) = check {
            saved.markSaved(except: controls, lighting: lighting)
        } else {
            saved.markSaved()
        }
        return .saved(saved, check)
    }

    /// Compares each changed control with what reading its layer back gives, both in the form the keyboard's records
    /// hold — so only what the keyboard changed counts — and each changed layer's lights, where they read back. A
    /// control outside the read isn't compared. The write has succeeded by now, so a read that fails only leaves its
    /// layer unchecked.
    private func readBack(
        _ written: KeyboardConfiguration, capabilities: KeyboardCapabilities, layout: KeyboardLayout
    ) async -> Check {
        guard case .records(let format) = capabilities.commands, capabilities.reading != .never else { return .notChecked }
        var differing: [Int: Set<ControlID>] = [:]
        var differingLighting: Set<Int> = []
        var unsure = false
        for layer in 0..<written.layerCount {
            let changes = layout.controls
                .filter { written.isChanged($0, layer: layer) }
                .compactMap { control in written.action(control, layer: layer).map { (control, $0) } }
            if !changes.isEmpty {
                do {
                    let read = try await repository.readActions(layer: layer, format: format, layout: layout)
                    for (control, action) in changes where !read.outside.contains(control) {
                        guard !read.unread.contains(control), let expected = repository.storedForm(of: action, format: format)
                        else {
                            unsure = true
                            continue
                        }
                        if read.actions[control] != expected { differing[layer, default: []].insert(control) }
                    }
                } catch {
                    unsure = true
                }
            }
            if written.layers[layer].lightingChanged, case .perKeyColor = capabilities.lighting,
               let lighting = written.lighting(layer: layer) {
                do {
                    if try await repository.readLighting(layer: layer) != lighting { differingLighting.insert(layer) }
                } catch {
                    unsure = true
                }
            }
        }
        if !differing.isEmpty || !differingLighting.isEmpty {
            return .differs(controls: differing, lighting: differingLighting)
        }
        return unsure ? .couldNotCheck : .matched
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
