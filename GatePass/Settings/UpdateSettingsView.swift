import SwiftUI

struct UpdateSettingsTab: View {
    @EnvironmentObject private var updater: GatePassUpdater
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox(gatePassCopy("自动检查", "Automatic checks", language: language)) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(gatePassCopy("自动检查 GatePass 更新", "Automatically check for GatePass updates", language: language))
                            .font(.callout)
                        Text(updateDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Picker(gatePassCopy("检查频率", "Check frequency", language: language), selection: $updater.updateFrequency) {
                        Text(gatePassCopy("从不", "Never", language: language)).tag(GatePassUpdateFrequency.none)
                        Text(gatePassCopy("每天", "Daily", language: language)).tag(GatePassUpdateFrequency.daily)
                        Text(gatePassCopy("每周", "Weekly", language: language)).tag(GatePassUpdateFrequency.weekly)
                        Text(gatePassCopy("每月", "Monthly", language: language)).tag(GatePassUpdateFrequency.monthly)
                    }
                    .labelsHidden()
                    .frame(width: 110)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            }

            GroupBox(gatePassCopy("最近版本", "Recent releases", language: language)) {
                releaseHistory
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 6)
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 10) {
                Button {
                    updater.checkForUpdates(sheet: false, force: false)
                } label: {
                    Label(gatePassCopy("检查更新", "Check for updates", language: language), systemImage: "arrow.clockwise")
                }

                Button {
                    updater.checkForUpdates(sheet: true, force: true, forceUpdate: true)
                } label: {
                    Label(gatePassCopy("重新安装当前版本", "Reinstall current version", language: language), systemImage: "arrow.counterclockwise")
                }

                Spacer()

                Button {
                    NSWorkspace.shared.open(URL(string: "https://github.com/iPotatow/GatePass/releases")!)
                } label: {
                    Label(gatePassCopy("发布页面", "Release page", language: language), systemImage: "arrow.up.right.square")
                }
            }
            .controlSize(.regular)
        }
        .padding(.top, 6)
    }

    private var updateDescription: String {
        switch updater.updateFrequency {
        case .none:
            return gatePassCopy("只在你手动检查时连接 GitHub。", "GitHub is contacted only when you check manually.", language: language)
        case .daily:
            return gatePassCopy("每天检查一次是否有新版本。", "Check once a day for a new version.", language: language)
        case .weekly:
            return gatePassCopy("每周检查一次是否有新版本。", "Check once a week for a new version.", language: language)
        case .monthly:
            return gatePassCopy("每月检查一次是否有新版本。", "Check once a month for a new version.", language: language)
        @unknown default:
            return gatePassCopy("按所选频率检查新版本。", "Check for new versions at the selected frequency.", language: language)
        }
    }

    @ViewBuilder
    private var releaseHistory: some View {
        if updater.releases.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "shippingbox")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text(gatePassCopy("暂无版本记录", "No release history", language: language))
                    .font(.callout.weight(.medium))
                Text(updater.updateFrequency == .none
                     ? gatePassCopy("自动检查已关闭。", "Automatic checks are off.", language: language)
                     : gatePassCopy("点按“检查更新”获取最新信息。", "Click “Check for updates” to fetch the latest information.", language: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(updater.releases.prefix(3))) { release in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(release.tagName)
                                .font(.headline)

                            if let notes = release.modifiedBody(owner: "iPotatow", repo: "GatePass") {
                                Text(AttributedString(notes))
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text(gatePassCopy("无法显示此版本的发布说明。", "Unable to display the release notes.", language: language))
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if release.id != updater.releases.prefix(3).last?.id {
                            Divider()
                        }
                    }
                }
                .padding(12)
            }
        }
    }
}
