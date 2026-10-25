import Foundation
import DataLayer
import Domain
import Presentation

/// The composition root: the one place that knows the concrete repositories. Everything else depends on
/// the Domain's protocols.
@MainActor
final class AppContainer {
    let editor: KeyboardEditorViewModel
    let deviceLog: DeviceLogViewModel

    init() {
        let log = DeviceLogStore()
        let profiles = UserDefaultsLayoutProfiles()
        let connection: any KeyboardConnectionRepository
        let device: any KeyboardDeviceRepository
        // The keyboard on USB or a simulated one, switched from the Simulator menu.
        let source = KeyboardSourceSwitch(log: log, initial: Self.initialSource())
        connection = source
        let keyboardDevice = KeyboardDevice(source: source, log: log)
        let keyboardSource = KeyboardSourceUseCase(repository: source)
        // Settings ▸ General ▸ Firmware Workarounds.
        keyboardDevice.preventsLightingKeyRepeat = { LightingKeyRepeatToggle.isOn }
        device = keyboardDevice

        editor = KeyboardEditorViewModel(
            observeConnection: ObserveConnectionUseCase(repository: connection),
            retryConnection: RetryConnectionUseCase(repository: connection),
            identifyKeyboard: IdentifyKeyboardUseCase(repository: device),
            resolveLayout: ResolveLayoutUseCase(profiles: profiles),
            chooseLayout: ChooseLayoutUseCase(profiles: profiles),
            readKeyboard: ReadKeyboardUseCase(repository: device),
            saveKeyboard: SaveKeyboardUseCase(repository: device),
            keyboardSource: keyboardSource)
        deviceLog = DeviceLogViewModel(log: DeviceLogUseCase(repository: log))
        editor.start()
        deviceLog.start()
    }

    /// A debug build started with `-SimulatedKeyboard <model id>` starts on a simulated keyboard
    /// (`SimulatedModel.id`, e.g. `8890-3`); every other start is on the keyboard on USB.
    private static func initialSource() -> KeyboardSource {
        #if DEBUG
        guard let id = UserDefaults.standard.string(forKey: "SimulatedKeyboard"),
              let model = SimulatedModel.all.first(where: { $0.id == id })
        else { return .hardware }
        return .simulated(model)
        #else
        return .hardware
        #endif
    }
}
