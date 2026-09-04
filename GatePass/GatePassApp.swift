import SwiftUI

@main
struct GatePassApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject var appState = AppState.shared
    @StateObject private var updater = GatePassUpdater(owner: "iPotatow", repo: "GatePass")
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            GatePassRootView()
                .environmentObject(appState)
                .environmentObject(updater)
                .environment(\.locale, appLanguage.locale)
                .sheet(isPresented: $updater.sheet, content: {
                    GatePassUpdateSheet(updater: updater)
                })
        }
        .commands {
            AboutCommand(appState: appState, updater: updater)
            CommandGroup(replacing: .newItem, addition: { })
        }
        .windowToolbarStyle(.unifiedCompact)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1040, height: 760)
    }
}

private struct GatePassUpdateSheet: View {
    @ObservedObject var updater: GatePassUpdater

    var body: some View {
        if updater.hasNewerGatePassRelease || updater.forceUpdateRequested || updater.isChecking {
            updater.getUpdateView()
        } else {
            GatePassNoUpdateView(updater: updater)
        }
    }
}

private struct GatePassNoUpdateView: View {
    @ObservedObject var updater: GatePassUpdater
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(.green)

            VStack(spacing: 5) {
                Text(gatePassCopy("已是最新版本", "You're up to date", language: language))
                    .font(.title2.weight(.semibold))
                Text(gatePassCopy(
                    "GatePass \(updater.currentVersion) 已经是 GitHub 上的最新版本。",
                    "GatePass \(updater.currentVersion) is already the latest release on GitHub.",
                    language: language
                ))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Button(gatePassCopy("关闭", "Close", language: language)) {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .frame(width: 500, height: 200)
        .padding(24)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            AppState.shared.refreshRecentApps()
            guard !AppState.shared.isLoading else { return }
            updateGatekeeperUI(appState: AppState.shared)
        }
    }

    // MARK: - File Opening

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        if filenames.count > 1 {
            updateOnMain {
                AppState.shared.multiDrop = true
            }
        }

        for filename in filenames {
            guard FileManager.default.fileExists(atPath: filename) else {
                printOS("File dropped on Dock icon doesn't exist: \(filename)")
                continue
            }

            let fileURL = URL(fileURLWithPath: filename)

            guard fileURL.pathExtension == "app" else {
                printOS("Dropped file is not an application bundle: \(filename)")
                continue
            }

            handleOpenedApp(url: fileURL, appState: AppState.shared)
        }
    }
}

private func handleOpenedApp(url: URL, appState: AppState) {
    updateOnMain {
        appState.status = "正在移除 App 的隔离标记"
        appState.isLoading = true
    }
    Task {
        await removeQuarantine(path: url.path, appState: appState)
    }
}
