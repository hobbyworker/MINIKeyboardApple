import Foundation
import Domain

/// The device log, kept in memory: what the connection and the device write, the log window reads.
@MainActor
public final class DeviceLogStore: DeviceLogRepository {
    private static let limit = 2000

    private var items: [DeviceLogEntry] = []
    private var continuations: [UUID: AsyncStream<[DeviceLogEntry]>.Continuation] = [:]

    public init() {}

    public func entries() async -> AsyncStream<[DeviceLogEntry]> {
        let (stream, continuation) = AsyncStream.makeStream(of: [DeviceLogEntry].self)
        let id = UUID()
        continuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in self?.continuations[id] = nil }
        }
        continuation.yield(items)
        return stream
    }

    public func clear() async {
        items.removeAll()
        publish()
    }

    func append(_ content: DeviceLogEntry.Content) {
        items.append(DeviceLogEntry(content))
        if items.count > Self.limit { items.removeFirst(items.count - Self.limit) }
        publish()
    }

    private func publish() {
        for continuation in continuations.values { continuation.yield(items) }
    }
}

/// Keeps every subscriber of a state stream up to date.
@MainActor
final class StateBroadcaster<Value: Sendable & Equatable> {
    private(set) var value: Value
    private var continuations: [UUID: AsyncStream<Value>.Continuation] = [:]

    init(_ value: Value) {
        self.value = value
    }

    func set(_ new: Value) {
        guard new != value else { return }
        value = new
        for continuation in continuations.values { continuation.yield(new) }
    }

    func stream() -> AsyncStream<Value> {
        let (stream, continuation) = AsyncStream.makeStream(of: Value.self)
        let id = UUID()
        continuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { @MainActor in self?.continuations[id] = nil }
        }
        continuation.yield(value)
        return stream
    }
}
