import SwiftUI

struct AboutCommand: Commands {
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue
    let appState: AppState
    let updater: GatePassUpdater
    init(appState: AppState, updater: GatePassUpdater) {
        self.appState = appState
        self.updater = updater
    }

    var body: some Commands {
        let language = AppLanguage(rawValue: languageRaw) ?? .system

        // Replace the About window menu option.
        CommandGroup(replacing: .appInfo) {

            Button {
                updater.checkForUpdates(sheet: true, force: false)
            } label: {
                Text(gatePassCopy("检查更新", "Check for Updates", language: language))
            }
            .keyboardShortcut("u", modifiers: .command)

            Button {
                DebugConsoleWindowController.shared.open()
            } label: {
                Text(gatePassCopy("调试控制台", "Debug Console", language: language))
            }
            .keyboardShortcut("d", modifiers: .command)

        }
    }
}
