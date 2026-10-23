import SwiftUI
import Presentation

/// What is known about the keyboard plugged in. Nothing is guessed: what the keyboard doesn't say shows as
/// not provided.
struct KeyboardInfoView: View {
    let info: KeyboardInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keyboard Information")
                .font(.headline)
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 14, verticalSpacing: 8) {
                row(Text(verbatim: "USB ID")) {
                    Text(verbatim: info.usbID).monospaced()
                }
                row(Text("Name")) { provided(info.name) }
                row(Text("Manufacturer")) { provided(info.manufacturer) }
                row(Text("Serial Number")) { provided(info.serialNumber) }
                // No USB descriptor names the chip.
                row(Text("Chip")) { provided(nil) }
                row(Text("Firmware")) { firmware }
                if let usb = info.usb {
                    row(Text(verbatim: "USB")) { Text(verbatim: usb) }
                }
                if let power = info.power {
                    row(Text("Power")) { Text(verbatim: "\(power)\u{00A0}mA") }
                }
                if !info.interfaces.isEmpty {
                    row(Text("Interfaces")) { interfaces }
                }
                row(Text("Configuration Channel")) { info.channel.text }
                row(Text("Commands")) { info.commands.text }
            }
            .font(.callout)
        }
        .padding(16)
        .frame(width: 460)
        .textSelection(.enabled)
    }

    private func row(_ title: Text, @ViewBuilder value: () -> some View) -> some View {
        GridRow {
            title.foregroundStyle(.secondary).gridColumnAlignment(.trailing)
            value()
        }
    }

    @ViewBuilder private func provided(_ value: String?) -> some View {
        if let value {
            Text(verbatim: value)
        } else {
            Text("Not provided by the keyboard").foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder private var firmware: some View {
        switch info.firmware {
        case .reported(let type, let keys, let knobs):
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "\(type)")
                Text("Keys: \(keys) · Knobs: \(knobs)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .release(let release):
            Text(verbatim: release)
        case .unknown:
            provided(nil)
        }
    }

    /// Each interface with what it is for; the one the app writes to is marked.
    private var interfaces: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(info.interfaces) { interface in
                HStack(spacing: 0) {
                    Text(verbatim: "\(interface.number)  ").monospacedDigit()
                    ForEach(Array(interface.roles.enumerated()), id: \.offset) { index, role in
                        if index > 0 { Text(verbatim: ", ") }
                        Text(role.title)
                    }
                    if interface.isConfiguration {
                        Text(verbatim: "  ←").foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
