import Domain

/// The payloads that write a configuration's changes, in the order the keyboard's vendor tool writes them.
struct WritePlan: Equatable, Sendable {
    struct Step: Equatable, Sendable {
        var payload: [UInt8]
        var pauseAfter: Duration = .zero
    }

    var steps: [Step] = []

    private mutating func append(_ payloads: [[UInt8]]) {
        steps += payloads.map { Step(payload: $0) }
    }

    private mutating func commit() {
        steps.append(Step(payload: K884xCommands.commit, pauseAfter: K884xCommands.commitPause))
    }

    /// Changed controls of one layer that the layout has, in control order.
    private static func changes(_ configuration: KeyboardConfiguration, layer: Int, layout: KeyboardLayout)
        -> [(control: ControlID, action: KeyAction)]
    {
        layout.controls
            .filter { configuration.isChanged($0, layer: layer) }
            .sorted()
            .compactMap { control in configuration.action(control, layer: layer).map { (control, $0) } }
    }

    /// The record a 884x keyboard keeps `control` in.
    private static func record(_ control: ControlID, in layout: KeyboardLayout) throws(KeyboardDeviceError) -> Int {
        guard let record = RecordNumbers.record(of: control, in: layout) else { throw .unsupported }
        return record
    }

    init(_ configuration: KeyboardConfiguration, commands: CommandSet, layout: KeyboardLayout) throws(KeyboardDeviceError) {
        let layers = 0..<configuration.layerCount
        switch commands {
        case .packets(let reportID):
            // One key at a time, each saved on its own (`Download_Click`).
            for layer in layers {
                for (control, action) in Self.changes(configuration, layer: layer, layout: layout) {
                    guard let number = K8890Numbering.number(of: control) else { continue }
                    append(try K8890Packets.download(number: number, action: action, layer: layer, reportID: reportID))
                }
                if configuration.layers[layer].lightingChanged, case .mode(let mode)? = configuration.lighting(layer: layer) {
                    append(K8890Packets.downloadLighting(mode: mode, layer: layer, reportID: reportID))
                }
            }

        case .records(.standard):
            // Every changed record, then — when a light changed — every layer's lights, then one commit if a
            // record was written (`Widget::HID_write`).
            var wroteRecords = false
            for layer in layers {
                for (control, action) in Self.changes(configuration, layer: layer, layout: layout) {
                    append([try RecordCodec.standard(action, recordID: try Self.record(control, in: layout), layer: layer)])
                    wroteRecords = true
                }
            }
            if configuration.layers.contains(where: \.lightingChanged) {
                for layer in layers {
                    guard case .perKey(let mode, let colors)? = configuration.lighting(layer: layer) else { continue }
                    append([K884xCommands.lighting(layer: layer, mode: mode, colors: colors)])
                }
            }
            if wroteRecords { commit() }

        case .records(.legacy):
            // Each layer's changed records, its lights in record 0, and a commit.
            for layer in layers {
                var wroteRecords = false
                for (control, action) in Self.changes(configuration, layer: layer, layout: layout) {
                    append([try RecordCodec.encode(action, recordID: try Self.record(control, in: layout), layer: layer, format: .legacy)])
                    wroteRecords = true
                }
                if configuration.layers[layer].lightingChanged, case .colorMode(let color, let mode)? = configuration.lighting(layer: layer) {
                    append([RecordCodec.legacyLighting(color: color, mode: mode, layer: layer)])
                    wroteRecords = true
                }
                if wroteRecords { commit() }
            }

        case .records(.unidentified):
            // One record at a time, each saved on its own.
            for layer in layers {
                for (control, action) in Self.changes(configuration, layer: layer, layout: layout) {
                    append([try RecordCodec.unidentified(action, recordID: try Self.record(control, in: layout), layer: layer)])
                    append(K884xCommands.unidentifiedSave)
                }
                if configuration.layers[layer].lightingChanged, case .colorMode(let color, let mode)? = configuration.lighting(layer: layer) {
                    append(K884xCommands.unidentifiedLighting(color: color, mode: mode, layer: layer))
                }
            }
        }
    }
}
