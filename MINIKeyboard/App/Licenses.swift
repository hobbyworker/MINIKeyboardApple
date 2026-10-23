import Foundation

/// The open source licenses, from the per-package files in `Resources/Licenses/` — whatever the
/// build bundles is picked up. The bodies are verbatim English; the localized intro is in the
/// About pane's sheet.
enum Licenses {
    /// Whether this build carries any license to show.
    static var areBundled: Bool { !licenseFiles().isEmpty }

    /// Every bundled per-package license, joined with `---` rules.
    static var markdown: String {
        let blocks = licenseFiles()
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { try? String(contentsOf: $0, encoding: .utf8) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return blocks.isEmpty ? "(license files not found in bundle)" : blocks.joined(separator: "\n\n---\n\n")
    }

    /// Every bundled `Licenses-*.md`. The build may keep the `Licenses/` folder or flatten it into
    /// the resources, so both are searched.
    private static func licenseFiles() -> [URL] {
        var byName: [String: URL] = [:]
        for subdirectory in ["Licenses", nil] {
            for url in Bundle.main.urls(forResourcesWithExtension: "md", subdirectory: subdirectory) ?? [] {
                let name = url.lastPathComponent
                if name.hasPrefix("Licenses-"), byName[name] == nil { byName[name] = url }
            }
        }
        return Array(byName.values)
    }
}
