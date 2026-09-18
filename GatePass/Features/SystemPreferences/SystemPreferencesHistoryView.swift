import SwiftUI

struct SystemPreferencesHistoryView: View {
    let language: AppLanguage

    @Environment(\.dismiss) private var dismiss
    @State private var records: [SystemPreferencesChangeResult] = []
    @State private var isLoading = true

    private let historyStore = SystemPreferencesHistoryStore()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: CoreSpacing.m) {
                VStack(alignment: .leading, spacing: CoreSpacing.xs) {
                    Text(gatePassCopy("操作历史", "History", language: language))
                        .coreTypography(CoreTypography.sectionTitle)
                        .foregroundStyle(CoreColor.textPrimary)
                    Text(gatePassCopy(
                        "记录最近 200 次系统偏好操作结果。",
                        "Shows the latest 200 System Preferences operations.",
                        language: language
                    ))
                    .coreTypography(CoreTypography.caption)
                    .foregroundStyle(CoreColor.textSecondary)
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
                .font(CoreTypography.controlFont)
                .keyboardShortcut(.defaultAction)
            }
            .padding(CoreSpacing.xl)

            Rectangle()
                .fill(CoreColor.divider)
                .frame(height: CoreMetrics.dividerWidth)

            Group {
                if isLoading {
                    VStack(spacing: CoreSpacing.s) {
                        ProgressView()
                        Text(gatePassCopy("正在读取历史记录…", "Loading history…", language: language))
                            .coreTypography(CoreTypography.caption)
                            .foregroundStyle(CoreColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if records.isEmpty {
                    CoreEmptyStateView(
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
                    HStack(spacing: CoreSpacing.m) {
                        Image(systemName: item.verified ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(item.verified ? CoreColor.success : CoreColor.danger)
                            .frame(width: 16)

                        Text(MacSystemPreferencesCatalog.byID[item.settingID]?.title(language: language) ?? item.settingID)
                            .coreTypography(CoreTypography.caption)
                            .foregroundStyle(CoreColor.textPrimary)
                            .lineLimit(1)

                        Spacer(minLength: CoreSpacing.m)

                        Text(resultText(item))
                            .coreTypography(CoreTypography.groupLabel)
                            .foregroundStyle(item.verified ? CoreColor.textSecondary : CoreColor.warning)
                    }
                    .padding(.vertical, CoreSpacing.xs)

                    if index < record.items.count - 1 {
                        Rectangle()
                            .fill(CoreColor.divider)
                            .frame(height: CoreMetrics.dividerWidth)
                    }
                }
            }
        } label: {
            HStack(spacing: CoreSpacing.m) {
                Image(systemName: record.failedCount == 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(record.failedCount == 0 ? CoreColor.success : CoreColor.warning)

                VStack(alignment: .leading, spacing: CoreSpacing.xs) {
                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .coreTypography(CoreTypography.control)
                        .foregroundStyle(CoreColor.textPrimary)
                    Text(gatePassCopy(
                        "修改 \(record.changedCount) 项 · 验证 \(verifiedCount) 项 · 失败 \(record.failedCount) 项",
                        "Changed \(record.changedCount) · Verified \(verifiedCount) · Failed \(record.failedCount)",
                        language: language
                    ))
                    .coreTypography(CoreTypography.caption)
                    .foregroundStyle(CoreColor.textSecondary)
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
