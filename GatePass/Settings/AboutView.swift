import SwiftUI

struct AboutView: View {
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    var body: some View {
        VStack(spacing: GatePassTheme.spaceXL) {
            Spacer(minLength: GatePassTheme.spaceS)

            VStack(spacing: GatePassTheme.spaceM) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .accessibilityHidden(true)

                VStack(spacing: GatePassTheme.spaceXS) {
                    Text(Bundle.main.name)
                        .gatePassTypography(GatePassTheme.typographyPageTitle)
                        .foregroundStyle(GatePassTheme.textPrimary)
                    Text(gatePassCopy(
                        "版本 \(Bundle.main.version) · 构建 \(Bundle.main.buildVersion)",
                        "Version \(Bundle.main.version) · Build \(Bundle.main.buildVersion)",
                        language: language
                    ))
                        .gatePassTypography(GatePassTheme.typographyCaption)
                        .foregroundStyle(GatePassTheme.textSecondary)
                }

                Text(gatePassCopy(
                    "专为受信任的本地 App 工作流打造。\n快速解除下载隔离，同时保留推荐的 App 来源策略。",
                    "Built for trusted local App workflows.\nRemove quarantine quickly while keeping the recommended app source policy.",
                    language: language
                ))
                    .gatePassTypography(GatePassTheme.typographyBody)
                    .foregroundStyle(GatePassTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: GatePassTheme.spaceM) {
                Button {
                    NSWorkspace.shared.open(URL(string: "https://github.com/sponsors/iPotatow")!)
                } label: {
                    Label(gatePassCopy("赞助项目", "Sponsor the project", language: language), systemImage: "heart")
                }

                Button {
                    NSWorkspace.shared.open(URL(string: "https://github.com/iPotatow/GatePass/issues/new/choose")!)
                } label: {
                    Label(gatePassCopy("反馈问题", "Report an issue", language: language), systemImage: "bubble.left.and.exclamationmark.bubble.right")
                }
            }
            .font(GatePassTheme.typeControl)
            .buttonStyle(.bordered)

            Spacer()

            Text(gatePassCopy("GatePass 是开源软件", "GatePass is open source", language: language))
                .gatePassTypography(GatePassTheme.typographyCaption)
                .foregroundStyle(GatePassTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(GatePassTheme.spaceXL)
    }
}
