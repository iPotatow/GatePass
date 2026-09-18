import SwiftUI

struct AboutView: View {
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    var body: some View {
        VStack(spacing: CoreSpacing.xl) {
            Spacer(minLength: CoreSpacing.s)

            VStack(spacing: CoreSpacing.m) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .accessibilityHidden(true)

                VStack(spacing: CoreSpacing.xs) {
                    Text(Bundle.main.name)
                        .coreTypography(CoreTypography.pageTitle)
                        .foregroundStyle(CoreColor.textPrimary)

                    CoreSupportingText(gatePassCopy(
                        "版本 \(Bundle.main.version) · 构建 \(Bundle.main.buildVersion)",
                        "Version \(Bundle.main.version) · Build \(Bundle.main.buildVersion)",
                        language: language
                    ))
                }

                Text(gatePassCopy(
                    "专为受信任的本地 App 工作流打造。\n快速解除下载隔离，同时保留推荐的 App 来源策略。",
                    "Built for trusted local App workflows.\nRemove quarantine quickly while keeping the recommended app source policy.",
                    language: language
                ))
                    .coreTypography(CoreTypography.body)
                    .foregroundStyle(CoreColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: CoreSpacing.m) {
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
            .font(CoreTypography.controlFont)
            .buttonStyle(.bordered)

            Spacer()

            Text(gatePassCopy("GatePass 是开源软件", "GatePass is open source", language: language))
                .coreTypography(CoreTypography.caption)
                .foregroundStyle(CoreColor.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(CoreSpacing.xl)
    }
}
