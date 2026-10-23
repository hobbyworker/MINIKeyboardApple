import AppKit
import SwiftUI

/// Settings ▸ About: the app, its version, updates and the open source licenses.
struct AboutPane: View {
    @State private var showsLicenses = false

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            if let icon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: icon).resizable().interpolation(.high).frame(width: 96, height: 96)
            }
            Text(AppDisplayName.current).font(.system(size: 22, weight: .semibold))
            Text("Version \(AppVersion.marketing) (build \(AppVersion.build))")
                .font(.callout)
                .foregroundStyle(.secondary)

            // The more frequent action first.
            VStack(spacing: 8) {
                CheckForUpdatesButton(fillsWidth: true)
                if Licenses.areBundled {
                    Button {
                        showsLicenses = true
                    } label: {
                        Text("Open Source Licenses").frame(maxWidth: .infinity)
                    }
                }
            }
            .controlSize(.large)
            .frame(width: 200)
            .padding(.top, 8)

            Spacer()
            // The same in every language; `verbatim:` keeps it out of the catalog.
            if !BrandInfo.copyright.isEmpty {
                Text(verbatim: BrandInfo.copyright)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showsLicenses) { LicensesSheet() }
    }
}

/// The bundled license bodies (`Licenses`) under a localized intro.
private struct LicensesSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Open Source Licenses").font(.title3.weight(.semibold))
                Spacer()
                Button("Close") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 10)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(AppDisplayName.current) uses the following open source packages. Below is the original license each package publishes in its source repository.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    MarkdownView(markdown: Licenses.markdown)
                }
                .padding(20)
            }
        }
        .frame(width: 620, height: 540)
    }
}
