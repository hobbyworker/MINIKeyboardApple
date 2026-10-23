#if DEBUG
import Domain

/// The keyboard the app talks to, switchable while it runs: the one on USB or a simulated one. A switch
/// is reported as "searching" and then the new keyboard, so the app starts over as after re-plugging. The
/// USB connection is made the first time it is chosen — an app that stays on a simulated keyboard never
/// opens a real one.
@MainActor
public final class KeyboardSourceSwitch: KeyboardConnectionRepository, KeyboardSourceRepository, ChannelProvider {
    @MainActor private enum Backend {
        case hardware(HardwareConnection)
        case simulated(SimulatedKeyboard)

        var connection: any KeyboardConnectionRepository {
            switch self {
            case .hardware(let connection): connection
            case .simulated(let keyboard): keyboard
            }
        }

        var channels: any ChannelProvider {
            switch self {
            case .hardware(let connection): connection
            case .simulated(let keyboard): keyboard
            }
        }
    }

    public private(set) var source: KeyboardSource
    private let log: DeviceLogStore
    private var hardware: HardwareConnection?
    private var simulated: [SimulatedModel: SimulatedKeyboard] = [:]
    private let state = StateBroadcaster(ConnectionState.searching)
    private var forwarding: Task<Void, Never>?

    public init(log: DeviceLogStore, initial: KeyboardSource = .hardware) {
        self.log = log
        source = initial
        follow(backend(for: initial))
    }

    public func connectionStates() async -> AsyncStream<ConnectionState> {
        state.stream()
    }

    public func retry() async {
        await backend(for: source).connection.retry()
    }

    public func current() async -> KeyboardSource { source }

    public func select(_ new: KeyboardSource) async {
        guard new != source else { return }
        forwarding?.cancel()
        source = new
        state.set(.searching)
        follow(backend(for: new))
    }

    var openChannel: (any ReportChannel)? { backend(for: source).channels.openChannel }

    private func backend(for source: KeyboardSource) -> Backend {
        switch source {
        case .hardware:
            if let hardware { return .hardware(hardware) }
            let connection = HardwareConnection(log: log)
            hardware = connection
            return .hardware(connection)
        case .simulated(let model):
            if let keyboard = simulated[model] { return .simulated(keyboard) }
            log.append(.event(.simulated(modelID: model.id)))
            let keyboard = SimulatedKeyboard(model: model, log: log)
            simulated[model] = keyboard
            return .simulated(keyboard)
        }
    }

    private func follow(_ backend: Backend) {
        let connection = backend.connection
        forwarding = Task { [weak self] in
            for await state in await connection.connectionStates() {
                guard let self, !Task.isCancelled else { return }
                self.state.set(state)
            }
        }
    }
}

extension KeyboardDevice {
    public convenience init(source: KeyboardSourceSwitch, log: DeviceLogStore) {
        self.init(channels: source, log: log)
    }
}
#endif
