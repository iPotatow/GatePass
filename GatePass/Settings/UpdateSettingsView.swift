import SwiftUI

struct UpdateSettingsTab: View {
    @EnvironmentObject private var updater: GatePassUpdater
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    var body: some View {
        VStack(alignment: .leading, spacing: GatePassTheme.spaceL) {
            GatePassPanel {
                VStack(alignment: .leading, spacing: GatePassTheme.spaceM) {
                    Text(gatePassCopy("更新来源", "Update source", language: language))
                        .gatePassTypography(GatePassTheme.typographySectionTitle)
                        .foregroundStyle(GatePassTheme.textPrimary)

                    HStack(alignment: .center, spacing: GatePassTheme.spaceL) {
                        VStack(alignment: .leading, spacing: GatePassTheme.spaceXS) {
                            Text(gatePassCopy("下载更新时使用的来源", "Source used for update downloads", language: language))
                                .gatePassTypography(GatePassTheme.typographyBody)
                                .foregroundStyle(GatePassTheme.textPrimary)
                            Text(updateSourceDescription)
                                .gatePassTypography(GatePassTheme.typographyCaption)
                                .foregroundStyle(GatePassTheme.textSecondary)
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
                        .font(GatePassTheme.typeControl)
                        .pickerStyle(.menu)
                        .frame(width: 220)
                    }

                    if updater.updateSource != .github {
                        Text(gatePassCopy(
                            "版本信息始终从 GitHub 获取；安装包和校验文件优先使用所选镜像，失败时自动回退到 GitHub。",
                            "Release metadata always comes from GitHub. The app archive and checksum prefer the selected mirror and fall back to GitHub if needed.",
                            language: language
                        ))
                            .gatePassTypography(GatePassTheme.typographyCaption)
                            .foregroundStyle(GatePassTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            GatePassPanel {
                VStack(alignment: .leading, spacing: GatePassTheme.spaceM) {
                    Text(gatePassCopy("自动检查", "Automatic checks", language: language))
                        .gatePassTypography(GatePassTheme.typographySectionTitle)
                        .foregroundStyle(GatePassTheme.textPrimary)

                    HStack(spacing: GatePassTheme.spaceL) {
                        VStack(alignment: .leading, spacing: GatePassTheme.spaceXS) {
                            Text(gatePassCopy("自动检查 GatePass 更新", "Automatically check for GatePass updates", language: language))
                                .gatePassTypography(GatePassTheme.typographyBody)
                                .foregroundStyle(GatePassTheme.textPrimary)
                            Text(updateDescription)
                                .gatePassTypography(GatePassTheme.typographyCaption)
                                .foregroundStyle(GatePassTheme.textSecondary)
                        }

                        Spacer()

                        Picker(gatePassCopy("检查频率", "Check frequency", language: language), selection: $updater.updateFrequency) {
                            Text(gatePassCopy("从不", "Never", language: language)).tag(GatePassUpdateFrequency.none)
                            Text(gatePassCopy("每天", "Daily", language: language)).tag(GatePassUpdateFrequency.daily)
                            Text(gatePassCopy("每周", "Weekly", language: language)).tag(GatePassUpdateFrequency.weekly)
                            Text(gatePassCopy("每月", "Monthly", language: language)).tag(GatePassUpdateFrequency.monthly)
                        }
                        .font(GatePassTheme.typeControl)
                        .labelsHidden()
                        .frame(width: 110)
                    }
                }
            }

            GatePassPanel {
                VStack(alignment: .leading, spacing: GatePassTheme.spaceM) {
                    Text(gatePassCopy("最近版本", "Recent releases", language: language))
                        .gatePassTypography(GatePassTheme.typographySectionTitle)
                        .foregroundStyle(GatePassTheme.textPrimary)

                    releaseHistory
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
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
            .font(GatePassTheme.typeControl)
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
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(GatePassTheme.textSecondary)
                Text(gatePassCopy("暂无版本记录", "No release history", language: language))
                    .gatePassTypography(GatePassTheme.typographyControl)
                    .foregroundStyle(GatePassTheme.textPrimary)
                Text(updater.updateFrequency == .none
                     ? gatePassCopy("自动检查已关闭。", "Automatic checks are off.", language: language)
                     : gatePassCopy("点按“检查更新”获取最新信息。", "Click “Check for updates” to fetch the latest information.", language: language))
                    .gatePassTypography(GatePassTheme.typographyCaption)
                    .foregroundStyle(GatePassTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: GatePassTheme.spaceL) {
                    ForEach(Array(updater.releases.prefix(3))) { release in
                        VStack(alignment: .leading, spacing: GatePassTheme.spaceS) {
                            Text(release.tagName)
                                .gatePassTypography(GatePassTheme.typographySectionTitle)
                                .foregroundStyle(GatePassTheme.textPrimary)

                            if let notes = release.releaseNotes {
                                Text(notes)
                                    .gatePassTypography(GatePassTheme.typographyBody)
                                    .foregroundStyle(GatePassTheme.textSecondary)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text(gatePassCopy("无法显示此版本的发布说明。", "Unable to display the release notes.", language: language))
                                    .gatePassTypography(GatePassTheme.typographyBody)
                                    .foregroundStyle(GatePassTheme.textSecondary)
                            }
                        }

                        if release.id != updater.releases.prefix(3).last?.id {
                            Rectangle()
                                .fill(GatePassTheme.divider)
                                .frame(height: GatePassTheme.dividerWidth)
                        }
                    }
                }
                .padding(GatePassTheme.spaceM)
            }
        }
    }
}
