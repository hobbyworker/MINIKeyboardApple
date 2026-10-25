import Domain

/// Talks to whichever keyboard the channel provider has open, in the commands it takes.
@MainActor
public final class KeyboardDevice: KeyboardDeviceRepository {
    private let channels: any ChannelProvider
    private let log: DeviceLogStore
    private let identifyTimeout: Duration
    private let replyTimeout: Duration
    private let pause: @Sendable (Duration) async -> Void

    /// Whether a lighting save on the 1189:8890 ends with the save that stops its key repeat — read at every
    /// write, so a change in Settings applies at once (`K8890Packets.downloadLighting`).
    public var preventsLightingKeyRepeat: () -> Bool = { true }

    public convenience init(connection: HardwareConnection, log: DeviceLogStore) {
        self.init(channels: connection, log: log)
    }

    /// The cross-platform app waits 10 ms for the identification answer; here a slow keyboard gets 600 ms,
    /// and every other answer a second.
    init(
        channels: any ChannelProvider, log: DeviceLogStore, identifyTimeout: Duration = .milliseconds(600),
        replyTimeout: Duration = .seconds(1),
        pause: @escaping @Sendable (Duration) async -> Void = { try? await Task.sleep(for: $0) }
    ) {
        self.channels = channels
        self.log = log
        self.identifyTimeout = identifyTimeout
        self.replyTimeout = replyTimeout
        self.pause = pause
    }

    private func channel() throws(KeyboardDeviceError) -> any ReportChannel {
        guard let channel = channels.openChannel else { throw .notConnected }
        return channel
    }

    private func send(_ payload: [UInt8], on channel: any ReportChannel) async throws(KeyboardDeviceError) {
        let report = channel.framing.frame(payload)
        log.append(.output(report))
        do {
            try await channel.write(report)
        } catch {
            if case .writeFailed(let code) = error {
                log.append(.event(.writeFailed(code: code)))
            }
            throw error
        }
    }

    public func askIdentity() async throws(KeyboardDeviceError) -> KeyboardIdentity? {
        let channel = try channel()
        channel.discardPendingReplies()
        try await send(K884xCommands.identify, on: channel)
        guard let reply = await channel.nextReply(timeout: identifyTimeout) else { return nil }
        guard let identity = K884xCommands.identity(from: reply) else { throw .invalidReply }
        return identity
    }

    public func readActions(layer: Int, format: RecordFormat, layout: KeyboardLayout) async throws(KeyboardDeviceError) -> [ControlID: KeyAction] {
        guard let request = K884xCommands.readRecords(layer: layer, format: format) else { throw .unsupported }
        let channel = try channel()
        channel.discardPendingReplies()
        try await send(request, on: channel)
        var actions: [ControlID: KeyAction] = [:]
        for recordID in 1...K884xCommands.readReplyCount(format) {
            guard let reply = await channel.nextReply(timeout: replyTimeout) else { throw .noReply }
            guard let control = RecordNumbers.control(inRecord: recordID, of: layout),
                  let action = RecordCodec.decode(K884xCommands.record(from: reply), format: format)
            else { continue }
            actions[control] = action
        }
        return actions
    }

    public func readLighting(layer: Int) async throws(KeyboardDeviceError) -> LayerLighting {
        let channel = try channel()
        channel.discardPendingReplies()
        try await send(K884xCommands.readLighting(layer: layer), on: channel)
        guard let reply = await channel.nextReply(timeout: replyTimeout) else { throw .noReply }
        guard let lighting = K884xCommands.lighting(from: reply) else { throw .invalidReply }
        return lighting
    }

    public func write(_ configuration: KeyboardConfiguration, commands: CommandSet, layout: KeyboardLayout) async throws(KeyboardDeviceError) {
        let plan = try WritePlan(
            configuration, commands: commands, layout: layout, preventLightingKeyRepeat: preventsLightingKeyRepeat())
        let channel = try channel()
        for step in plan.steps {
            try await send(step.payload, on: channel)
            if step.pauseAfter > .zero { await pause(step.pauseAfter) }
        }
    }
}
