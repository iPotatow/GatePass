import SwiftUI

struct SystemPreferencesHistoryView: View {
    let language: AppLanguage

    @Environment(\.dismiss) private var dismiss
    @State private var records: [SystemPreferencesChangeResult] = []
    @State private var isLoading = true

    private let historyStore = SystemPreferencesHistoryStore()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: GatePassTheme.spaceM) {
                VStack(alignment: .leading, spacing: GatePassTheme.spaceXS) {
                    Text(gatePassCopy("操作历史", "History", language: language))
                        .gatePassTypography(GatePassTheme.typographySectionTitle)
                        .foregroundStyle(GatePassTheme.textPrimary)
                    Text(gatePassCopy(
                        "记录最近 200 次系统偏好操作结果。",
                        "Shows the latest 200 System Preferences operations.",
                        language: language
                    ))
                    .gatePassTypography(GatePassTheme.typographyCaption)
                    .foregroundStyle(GatePassTheme.textSecondary)
                }

                Spacer()

                Button {
                    Task { await reload() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help(gatePassCopy("刷新", "Refresh", language: language))
                .accessibilityLabel(gatePassCopy("刷新历史记录", "Refresh history", language: language))
                .disabled(isLoading)

                Button(gatePassCopy("完成", "Done", language: language)) {
                    dismiss()
                }
                .font(GatePassTheme.typeControl)
                .keyboardShortcut(.defaultAction)
            }
            .padding(GatePassTheme.spaceXL)

            Rectangle()
                .fill(GatePassTheme.divider)
                .frame(height: GatePassTheme.dividerWidth)

            Group {
                if isLoading {
                    VStack(spacing: GatePassTheme.spaceS) {
                        ProgressView()
                        Text(gatePassCopy("正在读取历史记录…", "Loading history…", language: language))
                            .gatePassTypography(GatePassTheme.typographyCaption)
                            .foregroundStyle(GatePassTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if records.isEmpty {
                    GatePassEmptyStateView(
                        title: gatePassCopy("还没有操作记录", "No history yet", language: language),
                        systemImage: "clock.arrow.circlepath",
                        description: gatePassCopy(
                            "应用或恢复系统偏好后，结果会显示在这里。",
                            "Apply or restore System Preferences and the results will appear here.",
                            language: language
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(records) { record in
                        HistoryRecordRow(record: record, language: language)
                    }
                    .listStyle(.inset)
                }
            }
        }
        .frame(minWidth: 540, idealWidth: 680, maxWidth: 860)
        .frame(minHeight: 420, idealHeight: 540, maxHeight: 720)
        .task { await reload() }
    }

    @MainActor
    private func reload() async {
        isLoading = true
        records = await historyStore.load()
        isLoading = false
    }
}

private struct HistoryRecordRow: View {
    let record: SystemPreferencesChangeResult
    let language: AppLanguage

    @State private var expanded = false

    private var verifiedCount: Int {
        record.items.filter(\.verified).count
    }

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(spacing: 0) {
                ForEach(Array(record.items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: GatePassTheme.spaceM) {
                        Image(systemName: item.verified ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(item.verified ? GatePassTheme.semanticSuccess : GatePassTheme.semanticDanger)
                            .frame(width: 16)

                        Text(MacSystemPreferencesCatalog.byID[item.settingID]?.title(language: language) ?? item.settingID)
                            .gatePassTypography(GatePassTheme.typographyCaption)
                            .foregroundStyle(GatePassTheme.textPrimary)
                            .lineLimit(1)

                        Spacer(minLength: GatePassTheme.spaceM)

                        Text(resultText(item))
                            .gatePassTypography(GatePassTheme.typographyGroupLabel)
                            .foregroundStyle(item.verified ? GatePassTheme.textSecondary : GatePassTheme.semanticWarning)
                    }
                    .padding(.vertical, GatePassTheme.spaceXS)

                    if index < record.items.count - 1 {
                        Rectangle()
                            .fill(GatePassTheme.divider)
                            .frame(height: GatePassTheme.dividerWidth)
                    }
                }
            }
        } label: {
            HStack(spacing: GatePassTheme.spaceM) {
                Image(systemName: record.failedCount == 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(record.failedCount == 0 ? GatePassTheme.semanticSuccess : GatePassTheme.semanticWarning)

                VStack(alignment: .leading, spacing: GatePassTheme.spaceXS) {
                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .gatePassTypography(GatePassTheme.typographyControl)
                        .foregroundStyle(GatePassTheme.textPrimary)
                    Text(gatePassCopy(
                        "修改 \(record.changedCount) 项 · 验证 \(verifiedCount) 项 · 失败 \(record.failedCount) 项",
                        "Changed \(record.changedCount) · Verified \(verifiedCount) · Failed \(record.failedCount)",
                        language: language
                    ))
                    .gatePassTypography(GatePassTheme.typographyCaption)
                    .foregroundStyle(GatePassTheme.textSecondary)
                }
            }
        }
    }

    private func resultText(_ item: SystemPreferenceChangeItemResult) -> String {
        if item.verified {
            return item.outcome == .changed
                ? gatePassCopy("已修改", "Changed", language: language)
                : gatePassCopy("无需修改", "Unchanged", language: language)
        }
        return item.failureReason?.title(language: language)
            ?? gatePassCopy("执行失败", "Failed", language: language)
    }
}
