#if DEBUG
import Domain

/// A keyboard that exists only in the app, for trying every keyboard without owning it. It takes the
/// same reports a real one does, through the same codecs, and answers as its firmware would: a 884x
/// keyboard that answers says who it is and reads back what was written to it.
@MainActor
final class SimulatedKeyboard: ReportChannel, ChannelProvider, KeyboardConnectionRepository {
    let model: SimulatedModel
    let framing: ReportFraming
    private let log: DeviceLogStore
    private let replies = ReplyQueue()
    /// Records by layer (from 1) and record number, as written.
    private(set) var records: [Int: [Int: [UInt8]]] = [:]
    /// Standard-format lights by layer (from 0): the mode and 16 colours, as written.
    private(set) var lighting: [Int: [UInt8]] = [:]
    /// Every payload written, in order.
    private(set) var written: [[UInt8]] = []

    init(model: SimulatedModel, log: DeviceLogStore) {
        self.model = model
        self.log = log
        switch model.kind {
        case .k8890(let reportID): framing = ReportFraming(reportID: reportID, length: reportID == 0 ? 64 : 65)
        case .identified, .unidentified: framing = ReportFraming(reportID: K884xCommands.reportID, length: K884xCommands.reportLength)
        }
    }

    var keyboard: ConnectedKeyboard {
        ConnectedKeyboard(
            usb: model.usb, family: model.family, interfaceNumber: model.family.configurationInterface,
            channel: .simulated, reportID: framing.reportID, reportLength: framing.length, details: nil)
    }

    // MARK: - KeyboardConnectionRepository, ChannelProvider

    func connectionStates() async -> AsyncStream<ConnectionState> {
        let (stream, continuation) = AsyncStream.makeStream(of: ConnectionState.self)
        continuation.yield(.connected(keyboard))
        return stream
    }

    func retry() async {}

    var openChannel: (any ReportChannel)? { self }

    // MARK: - ReportChannel

    func write(_ report: [UInt8]) async throws(KeyboardDeviceError) {
        let payload = framing.reportID == 0 ? report : Array(report.dropFirst())
        written.append(payload)
        guard case .identified(let identity) = model.kind else {
            if case .unidentified = model.kind, payload.first == 0xFE, payload.count > 2 {
                records[Int(payload[2]), default: [:]][Int(payload[1])] = payload
            }
            return
        }
        switch (payload.first, payload.count > 3 ? payload[1] : 0) {
        case (0xFB, _):
            reply([0xFB, UInt8(identity.keyCount), UInt8(identity.knobCount), UInt8(identity.type)])
        case (0xFA, 0xB0):
            let layer = Int(payload[2])
            reply([0xB0] + (lighting[layer] ?? Self.initialLighting))
        case (0xFA, _):
            let layer = Int(payload[3])
            let count = K884xCommands.readReplyCount(identity.recordFormat)
            for id in 1...count {
                reply(records[layer]?[id] ?? Self.initialRecord(id: id, layer: layer))
            }
        case (0xFD, _) where payload.count > 2 && payload[1] != 0xFE:
            records[Int(payload[2]), default: [:]][Int(payload[1])] = payload
        case (0xFE, 0xB0) where identity.recordFormat == .standard:
            lighting[Int(payload[2])] = Array(payload[3..<(4 + 3 * LightingSupport.colorKeyCount)])
        case (0xFE, 0xB0):
            records[Int(payload[2]), default: [:]][0] = payload
        default:
            break
        }
    }

    func discardPendingReplies() {
        replies.discard()
    }

    func nextReply(timeout: Duration) async -> [UInt8]? {
        await replies.next(timeout: timeout)
    }

    private func reply(_ payload: [UInt8]) {
        let report = framing.frame(payload)
        log.append(.input(report))
        replies.receive(report)
    }

    /// What the cross-platform app starts a record as: `FD <record> <layer> 01`.
    private static func initialRecord(id: Int, layer: Int) -> [UInt8] {
        [0xFD, UInt8(id), UInt8(layer), 0x01] + [UInt8](repeating: 0, count: 60)
    }

    private static let initialLighting: [UInt8] =
        [0] + KeyColor.defaultKeyColors.flatMap { [$0.red, $0.green, $0.blue] }
}
#endif
