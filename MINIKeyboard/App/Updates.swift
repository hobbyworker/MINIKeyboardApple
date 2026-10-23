import SwiftUI
#if canImport(Sparkle)
import Combine
import Sparkle
#endif

/// Updates through Sparkle, against the feed and key in Info.plist (SUFeedURL · SUPublicEDKey).
/// Without both — or in a build without Sparkle — nothing here shows or runs.
@MainActor
enum Updates {
    /// Called once at launch: starts Sparkle's scheduled checks.
    static func start() {
        #if canImport(Sparkle)
        if BrandInfo.hasUpdates { _ = UpdaterCoordinator.shared }
        #endif
    }

    /// Whether this build checks for updates at all.
    static var isAvailable: Bool {
        #if canImport(Sparkle)
        return BrandInfo.hasUpdates
        #else
        return false
        #endif
    }
}

/// **Check for Updates…** — the app menu's item, and Settings ▸ About's full-width button.
struct CheckForUpdatesButton: View {
    var fillsWidth = false

    var body: some View {
        #if canImport(Sparkle)
        if BrandInfo.hasUpdates {
            SparkleCheckButton(updater: .shared, fillsWidth: fillsWidth)
        }
        #endif
    }
}

/// Settings ▸ General ▸ **Check for updates automatically**.
struct AutomaticUpdatesToggle: View {
    var body: some View {
        #if canImport(Sparkle)
        if BrandInfo.hasUpdates {
            SparkleAutomaticToggle(updater: .shared)
        }
        #endif
    }
}

#if canImport(Sparkle)
@MainActor
@Observable
final class UpdaterCoordinator {
    /// Made at launch (`Updates.start`) and kept for the life of the app.
    static let shared = UpdaterCoordinator()

    @ObservationIgnored let controller: SPUStandardUpdaterController

    /// Off while Sparkle is mid-check.
    private(set) var canCheckForUpdates = false

    /// Sparkle owns the storage (its SU* keys in UserDefaults): writes are forwarded, and reads
    /// follow Sparkle over KVO, so a change made in its own prompt shows here too.
    var automaticallyChecksForUpdates: Bool {
        didSet {
            // Only a flip made here is forwarded, not the assignment coming back from KVO.
            if controller.updater.automaticallyChecksForUpdates != automaticallyChecksForUpdates {
                controller.updater.automaticallyChecksForUpdates = automaticallyChecksForUpdates
            }
        }
    }

    @ObservationIgnored private var cancellables: Set<AnyCancellable> = []

    private init() {
        // Without a feed and its key there is nothing to check against, and an updater that
        // can't verify a download refuses to run.
        let controller = SPUStandardUpdaterController(
            startingUpdater: BrandInfo.hasUpdates, updaterDelegate: nil, userDriverDelegate: nil)
        self.controller = controller
        automaticallyChecksForUpdates = controller.updater.automaticallyChecksForUpdates

        // `.initial` delivers the current value at once, so the menu item starts out right.
        controller.updater.publisher(for: \.canCheckForUpdates, options: [.initial, .new])
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.canCheckForUpdates = $0 }
            .store(in: &cancellables)
        controller.updater.publisher(for: \.automaticallyChecksForUpdates, options: [.new])
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.automaticallyChecksForUpdates = $0 }
            .store(in: &cancellables)
    }

    /// A check the user asked for — Sparkle's own progress and result windows.
    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}

private struct SparkleCheckButton: View {
    let updater: UpdaterCoordinator
    let fillsWidth: Bool

    var body: some View {
        Button {
            updater.checkForUpdates()
        } label: {
            Text("Check for Updates…")
                .frame(maxWidth: fillsWidth ? .infinity : nil)
        }
        .disabled(!updater.canCheckForUpdates)
    }
}

private struct SparkleAutomaticToggle: View {
    @Bindable var updater: UpdaterCoordinator

    var body: some View {
        Toggle("Check for updates automatically", isOn: $updater.automaticallyChecksForUpdates)
    }
}
#endif
