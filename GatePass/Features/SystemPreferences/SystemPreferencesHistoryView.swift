import SwiftUI

struct SystemPreferencesHistoryView: View {
    let language: AppLanguage

    @Environment(\.dismiss) private var dismiss
    @State private var records: [SystemPreferencesChangeResult] = []
    @State private var isLoading = true

    private let historyStore = SystemPreferencesHistoryStore()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(gatePassCopy("操作历史", "History", language: language))
                        .font(.title3.bold())
                    Text(gatePassCopy(
                        "记录最近 200 次系统偏好操作结果。",
                        "Shows the latest 200 System Preferences operations.",
                        language: language
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                .keyboardShortcut(.defaultAction)
            }
            .padding(20)

            Divider()

            Group {
                if isLoading {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text(gatePassCopy("正在读取历史记录…", "Loading history…", language: language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(records) { record in
                                HistoryRecordCard(record: record, language: language)
                            }
                        }
                        .padding(16)
                    }
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

private struct HistoryRecordCard: View {
    let record: SystemPreferencesChangeResult
    let language: AppLanguage

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    private var verifiedCount: Int {
        record.items.filter(\.verified).count
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.15)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: record.failedCount == 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(record.failedCount == 0 ? Color.green : Color.orange)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.callout.weight(.medium))
                        Text(gatePassCopy(
                            "修改 \(record.changedCount) 项 · 验证 \(verifiedCount) 项 · 失败 \(record.failedCount) 项",
                            "Changed \(record.changedCount) · Verified \(verifiedCount) · Failed \(record.failedCount)",
                            language: language
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                }
                .contentShape(Rectangle())
                .padding(13)
            }
            .buttonStyle(.plain)
            .accessibilityValue(Text(
                expanded
                    ? gatePassCopy("已展开", "Expanded", language: language)
                    : gatePassCopy("已折叠", "Collapsed", language: language)
            ))
            .accessibilityHint(Text(
                gatePassCopy("双击以展开或折叠详情", "Double-click to expand or collapse details", language: language)
            ))

            if expanded {
                Divider()
                    .padding(.leading, 42)

                VStack(spacing: 0) {
                    ForEach(Array(record.items.enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 10) {
                            Image(systemName: item.verified ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(item.verified ? Color.green : Color.red)
                                .frame(width: 16)

                            Text(MacSystemPreferencesCatalog.byID[item.settingID]?.title(language: language) ?? item.settingID)
                                .font(.caption)
                                .lineLimit(1)

                            Spacer(minLength: 12)

                            Text(resultText(item))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(item.verified ? Color.secondary : Color.orange)
                        }
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)

                        if index < record.items.count - 1 {
                            Divider()
                                .padding(.leading, 42)
                        }
                    }
                }
            }
        }
        .background(GatePassTheme.rowBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(GatePassTheme.border, lineWidth: 1)
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
