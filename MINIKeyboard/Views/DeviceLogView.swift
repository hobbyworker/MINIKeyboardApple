import AppKit
import SwiftUI
import Presentation

/// The reports written to the keyboard and its answers, for checking what a keyboard does. A report shows on
/// one line up to the zero padding at its end; opened, it shows every byte.
struct DeviceLogView: View {
    @Environment(DeviceLogViewModel.self) private var log
    @State private var expanded: Set<UUID> = []
    /// Opens with every report shown in full.
    var startsExpanded = false

    static let timeFormat = Date.FormatStyle(date: .omitted, time: .standard).secondFraction(.fractional(3))

    var body: some View {
        let entries = log.entries
        let expandable = entries.filter(Self.canExpand).map(\.id)
        let allExpanded = !expandable.isEmpty && expandable.allSatisfy(expanded.contains)
        VStack(spacing: 0) {
            HStack {
                Text("Packets: \(entries.count)")
                    .foregroundStyle(.secondary)
                Spacer()
                if allExpanded {
                    Button("Collapse All") { expanded = [] }
                } else {
                    Button("Expand All") { expanded = Set(expandable) }
                        .disabled(expandable.isEmpty)
                }
                Button("Copy") { copy(entries) }
                    .disabled(entries.isEmpty)
                Button("Clear") {
                    log.clear()
                    expanded = []
                }
                .disabled(entries.isEmpty)
            }
            .padding(10)
            Divider()
            if entries.isEmpty {
                Text("No packets yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List(entries) { entry in
                        LogRow(line: entry, canExpand: Self.canExpand(entry), isExpanded: binding(entry.id))
                            .id(entry.id)
                    }
                    .onChange(of: entries.last?.id) {
                        if let last = entries.last { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
        }
        .frame(minWidth: 640, minHeight: 320)
        .onAppear {
            if startsExpanded { expanded = Set(expandable) }
        }
    }

    /// A report with more to show than its one line.
    private static func canExpand(_ line: DeviceLogViewModel.Line) -> Bool {
        line.event == nil && (line.isShortened || line.bytes.count > 16)
    }

    private func binding(_ id: UUID) -> Binding<Bool> {
        Binding(
            get: { expanded.contains(id) },
            set: { open in
                if open { expanded.insert(id) } else { expanded.remove(id) }
            })
    }

    /// Every line, every byte of each report.
    private func copy(_ entries: [DeviceLogViewModel.Line]) {
        let text = entries.map { entry in
            let mark = switch entry.direction {
            case .output: "OUT"
            case .input: "IN "
            case .event: "-- "
            }
            let body = entry.event.map { String(localized: $0.message) } ?? entry.hex
            return "\(entry.date.formatted(Self.timeFormat)) \(mark) \(body)"
        }
        .joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

/// One line of the log; a report that has more opens below to every byte, 16 to a row.
private struct LogRow: View {
    let line: DeviceLogViewModel.Line
    let canExpand: Bool
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Button {
                    isExpanded.toggle()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .opacity(canExpand ? 1 : 0)
                .disabled(!canExpand)
                .help(isExpanded ? Text("Collapse") : Text("Expand"))
                .accessibilityLabel(isExpanded ? Text("Collapse") : Text("Expand"))
                Text(line.date, format: DeviceLogView.timeFormat)
                    .foregroundStyle(.secondary)
                Image(systemName: symbol)
                    .foregroundStyle(color)
                    .frame(width: 14)
                if let event = line.event {
                    Text(event.message)
                } else {
                    Text(verbatim: line.summary)
                        .textSelection(.enabled)
                    if line.isShortened {
                        HStack(spacing: 3) {
                            Text(verbatim: "…")
                            Text("\(line.bytes.count) bytes")
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            if isExpanded && canExpand {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(Array(line.rows.enumerated()), id: \.offset) { _, row in
                        Text(verbatim: row)
                    }
                }
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .padding(.leading, 22)
            }
        }
        .font(.system(size: 11, design: .monospaced))
    }

    private var symbol: String {
        switch line.direction {
        case .output: "arrow.up.circle"
        case .input: "arrow.down.circle"
        case .event: "info.circle"
        }
    }

    private var color: Color {
        switch line.direction {
        case .output: .blue
        case .input: .green
        case .event: .secondary
        }
    }
}
