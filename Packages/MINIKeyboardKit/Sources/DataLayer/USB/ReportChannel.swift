import Foundation
import Domain

/// How payloads become reports on a keyboard's configuration interface: the report ID first unless it is
/// 0, then the payload, zero-padded to the report's length.
struct ReportFraming: Hashable, Sendable {
    var reportID: UInt8
    /// Bytes per report, the report ID included.
    var length: Int

    func frame(_ payload: [UInt8]) -> [UInt8] {
        var bytes = reportID == 0 ? payload : [reportID] + payload
        if bytes.count < length { bytes += [UInt8](repeating: 0, count: length - bytes.count) }
        return bytes
    }
}

/// The open configuration interface: reports out, and the keyboard's answers in.
@MainActor
protocol ReportChannel: AnyObject {
    var framing: ReportFraming { get }

    /// Writes one report, as framed.
    func write(_ report: [UInt8]) async throws(KeyboardDeviceError)

    /// Drops answers that came before a new request.
    func discardPendingReplies()

    /// The next answer, its report ID first, or nil when none comes in time.
    func nextReply(timeout: Duration) async -> [UInt8]?
}

/// Whoever has the channel open — the connection to the keyboard on USB, or the simulator.
@MainActor
protocol ChannelProvider: AnyObject {
    var openChannel: (any ReportChannel)? { get }
}

/// Answers kept for whoever asks next.
@MainActor
final class ReplyQueue {
    private var pending: [[UInt8]] = []
    private var waiter: CheckedContinuation<[UInt8]?, Never>?
    private var timeout: Task<Void, Never>?

    func receive(_ reply: [UInt8]) {
        if let waiter {
            self.waiter = nil
            timeout?.cancel()
            waiter.resume(returning: reply)
        } else {
            pending.append(reply)
            if pending.count > 128 { pending.removeFirst() }
        }
    }

    func discard() {
        pending.removeAll()
    }

    func next(timeout duration: Duration) async -> [UInt8]? {
        if !pending.isEmpty { return pending.removeFirst() }
        guard waiter == nil else { return nil }
        return await withCheckedContinuation { continuation in
            waiter = continuation
            timeout = Task { [weak self] in
                try? await Task.sleep(for: duration)
                guard !Task.isCancelled else { return }
                self?.finish(with: nil)
            }
        }
    }

    /// Ends a wait — with nothing, when the keyboard went away.
    func finish(with reply: [UInt8]?) {
        guard let waiter else { return }
        self.waiter = nil
        timeout?.cancel()
        waiter.resume(returning: reply)
    }
}
