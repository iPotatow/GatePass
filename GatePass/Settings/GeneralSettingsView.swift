import SwiftUI

struct GeneralSettingsTab: View {
    @AppStorage("gatepass.general.autoLaunch") private var autoLaunch = true
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    var body: some View {
        Form {
            Section(gatePassCopy("应用语言", "App Language", language: language)) {
                Picker(gatePassCopy("界面语言", "Interface language", language: language), selection: $languageRaw) {
                    ForEach(AppLanguage.allCases) { option in
                        Text(option.displayName(in: language))
                            .tag(option.rawValue)
                    }
                }

                Text(gatePassCopy(
                    "语言更改会立即应用到主窗口和设置。",
                    "Changes apply immediately to the main window and Settings.",
                    language: language
                ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(gatePassCopy("处理完成后", "After Processing", language: language)) {
                Toggle(
                    gatePassCopy("解除隔离后自动打开 App", "Open the App after removing quarantine", language: language),
                    isOn: $autoLaunch
                )

                Text(gatePassCopy(
                    "仅在一次处理一个 App 时生效。关闭后，GatePass 只移除隔离属性。",
                    "Only applies when processing one App at a time. When off, GatePass only removes the quarantine attribute.",
                    language: language
                ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        }
        .formStyle(.grouped)
    }
}
