import SwiftUI

struct UpdateSettingsTab: View {
    @EnvironmentObject private var updater: GatePassUpdater
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GatePassTheme.spaceL) {
            GroupBox(gatePassCopy("更新来源", "Update source", language: language)) {
                VStack(alignment: .leading, spacing: GatePassTheme.spaceM) {
                    HStack(alignment: .center, spacing: GatePassTheme.spaceL) {
                        VStack(alignment: .leading, spacing: GatePassTheme.spaceXS) {
                            Text(gatePassCopy("下载更新时使用的来源", "Source used for update downloads", language: language))
                                .font(.callout)
                            Text(updateSourceDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Picker(
                            gatePassCopy("更新来源", "Update source", language: language),
                            selection: $updater.updateSource
                        ) {
                            Text(gatePassCopy("GitHub", "GitHub", language: language))
                                .tag(GatePassUpdateSource.github)
                            Text("gh-proxy.com")
                                .tag(GatePassUpdateSource.ghProxy)
                            Text("ghproxy.net")
                                .tag(GatePassUpdateSource.ghproxyNet)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 220)
                    }

                    if updater.updateSource != .github {
                        Text(gatePassCopy(
                            "版本信息始终从 GitHub 获取；安装包和校验文件优先使用所选镜像，失败时自动回退到 GitHub。",
                            "Release metadata always comes from GitHub. The app archive and checksum prefer the selected mirror and fall back to GitHub if needed.",
                            language: language
                        ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, GatePassTheme.spaceS)
                .padding(.horizontal, GatePassTheme.spaceXS)
            }

            GroupBox(gatePassCopy("自动检查", "Automatic checks", language: language)) {
                HStack(spacing: GatePassTheme.spaceL) {
                    VStack(alignment: .leading, spacing: GatePassTheme.spaceXS) {
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
                .padding(.vertical, GatePassTheme.spaceS)
                .padding(.horizontal, GatePassTheme.spaceXS)
            }

            GroupBox(gatePassCopy("最近版本", "Recent releases", language: language)) {
                releaseHistory
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, GatePassTheme.spaceS)
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: GatePassTheme.spaceM) {
                Button {
                    updater.checkForUpdates(reason: .manual)
                } label: {
                    Label(gatePassCopy("检查更新", "Check for updates", language: language), systemImage: "arrow.clockwise")
                }
                .disabled(updater.isChecking || updater.isUpdating)

                Button {
                    updater.checkForUpdates(reason: .reinstallCurrent)
                } label: {
                    Label(gatePassCopy("重新安装当前版本", "Reinstall current version", language: language), systemImage: "arrow.counterclockwise")
                }
                .disabled(updater.isChecking || updater.isUpdating)

                Spacer()

                Button {
                    NSWorkspace.shared.open(URL(string: "https://github.com/iPotatow/GatePass/releases")!)
                } label: {
                    Label(gatePassCopy("发布页面", "Release page", language: language), systemImage: "arrow.up.right.square")
                }
            }
            .controlSize(.regular)
        }
        .padding(.top, GatePassTheme.spaceS)
    }

    private var updateDescription: String {
        switch updater.updateFrequency {
        case .none:
            return gatePassCopy("只在你手动检查时从 GitHub 获取版本信息。", "Only fetch release information from GitHub when you check manually.", language: language)
        case .daily:
            return gatePassCopy("每天从 GitHub 检查一次是否有新版本。", "Check GitHub once a day for a new version.", language: language)
        case .weekly:
            return gatePassCopy("每周从 GitHub 检查一次是否有新版本。", "Check GitHub once a week for a new version.", language: language)
        case .monthly:
            return gatePassCopy("每月从 GitHub 检查一次是否有新版本。", "Check GitHub once a month for a new version.", language: language)
        @unknown default:
            return gatePassCopy("按所选频率从 GitHub 检查新版本。", "Check GitHub for new versions at the selected frequency.", language: language)
        }
    }

    private var updateSourceDescription: String {
        switch updater.updateSource {
        case .github:
            return gatePassCopy(
                "直接从 GitHub 下载安装包和校验文件。",
                "Download the app archive and checksum files directly from GitHub.",
                language: language
            )
        case .ghProxy, .ghproxyNet, .legacyMirror:
            return gatePassCopy(
                "优先通过 \(updater.updateSource.displayName) 下载；镜像失败时自动回退到 GitHub。",
                "Prefer \(updater.updateSource.displayName) for downloads and fall back to GitHub if the mirror fails.",
                language: language
            )
        }
    }

    @ViewBuilder
    private var releaseHistory: some View {
        if updater.releases.isEmpty {
            VStack(spacing: GatePassTheme.spaceS) {
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
                LazyVStack(alignment: .leading, spacing: GatePassTheme.spaceL) {
                    ForEach(Array(updater.releases.prefix(3))) { release in
                        VStack(alignment: .leading, spacing: GatePassTheme.spaceS) {
                            Text(release.tagName)
                                .font(.headline)

                            if let notes = release.releaseNotes {
                                Text(notes)
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
                .padding(GatePassTheme.spaceM)
            }
        }
    }
}
