import SwiftUI

struct SystemPreferencesView: View {
    @ObservedObject var store: SystemPreferencesStore
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue
    @State private var selectedComponent: SystemPreferenceComponent?
    @State private var showHistory = false

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    private var visibleItems: [SystemPreferenceItem] {
        guard let catalog = store.catalog else { return [] }
        return catalog.items.filter { item in
            if store.showPendingOnly && !store.pendingSettingIDs.contains(item.id) { return false }
            if let selectedComponent, item.definition.component != selectedComponent { return false }
            return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            VStack(spacing: GatePassTheme.sectionSpacing) {
                filters
                settingsList
            }
            .frame(maxWidth: GatePassTheme.contentMaxWidth, maxHeight: .infinity, alignment: .topLeading)
            .padding(GatePassTheme.contentBodyPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            Divider()
            applyBar
        }
        .task {
            if store.catalog == nil {
                await store.scan()
                store.selectMode(.unchanged)
            }
        }
        .alert(
            gatePassCopy("确认高风险设置", "Confirm high-risk settings", language: language),
            isPresented: Binding(
                get: { store.pendingRiskPlan != nil },
                set: { if !$0 { store.pendingRiskPlan = nil } }
            )
        ) {
            Button(gatePassCopy("取消", "Cancel", language: language), role: .cancel) {
                store.pendingRiskPlan = nil
            }
            Button(gatePassCopy("继续应用", "Apply anyway", language: language), role: .destructive) {
                Task { await store.confirmRiskPlan() }
            }
        } message: {
            Text(gatePassCopy(
                "所选更改包含会影响锁屏或安全行为的设置。GatePass 会保存恢复记录，但仍建议确认后再继续。",
                "The selected changes include settings that affect lock-screen or security behavior. GatePass keeps a recovery record, but you should review them before continuing.",
                language: language
            ))
        }
        .alert(
            gatePassCopy("系统偏好操作失败", "System Preferences operation failed", language: language),
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )
        ) {
            Button(gatePassCopy("关闭", "Close", language: language)) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .sheet(item: $store.lastResult) { result in
            SystemPreferencesResultView(result: result, language: language)
        }
        .sheet(isPresented: $showHistory) {
            SystemPreferencesHistoryView(language: language)
        }
    }

    private var header: some View {
        GatePassPageHeader(
            title: gatePassCopy("系统偏好", "System Preferences", language: language)
        ) {
            HStack(spacing: GatePassTheme.pageHeaderActionGap) {
                Button {
                    Task { await store.scan() }
                } label: {
                    if store.isScanning {
                        HStack(spacing: GatePassTheme.spaceS) {
                            ProgressView()
                                .controlSize(.small)
                            Text(gatePassCopy("正在扫描…", "Scanning…", language: language))
                        }
                    } else {
                        Label(gatePassCopy("重新扫描", "Rescan", language: language), systemImage: "arrow.clockwise")
                    }
                }
                .frame(height: GatePassTheme.controlHeightCompact)
                .disabled(store.isScanning || store.isApplying)

                Button {
                    Task { await store.restorePreviousOptimization() }
                } label: {
                    Label(gatePassCopy("恢复上次更改", "Restore previous changes", language: language), systemImage: "arrow.uturn.backward")
                }
                .frame(height: GatePassTheme.controlHeightCompact)
                .disabled(store.catalog?.recoveryAvailable != true || store.isScanning || store.isApplying)

                Button {
                    showHistory = true
                } label: {
                    Label(gatePassCopy("历史", "History", language: language), systemImage: "clock.arrow.circlepath")
                }
                .frame(height: GatePassTheme.controlHeightCompact)
            }
            .controlSize(.small)
        }
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GatePassTheme.spaceS) {
                filterButton(
                    gatePassCopy("全部", "All", language: language),
                    systemImage: "square.grid.2x2",
                    active: selectedComponent == nil && !store.showPendingOnly
                ) {
                    selectedComponent = nil
                    store.showPendingOnly = false
                }

                filterButton(
                    gatePassCopy("待应用 \(store.pendingCount)", "Pending \(store.pendingCount)", language: language),
                    systemImage: "clock.badge.exclamationmark",
                    active: store.showPendingOnly
                ) {
                    selectedComponent = nil
                    store.showPendingOnly = true
                }

                ForEach(SystemPreferenceComponent.allCases) { component in
                    let count = store.catalog?.items.filter { $0.definition.component == component }.count ?? 0
                    if count > 0 {
                        filterButton(
                            "\(component.title(language: language)) \(count)",
                            systemImage: component.icon,
                            active: selectedComponent == component && !store.showPendingOnly
                        ) {
                            store.showPendingOnly = false
                            selectedComponent = component
                        }
                    }
                }
            }
        }
    }

    private func filterButton(
        _ title: String,
        systemImage: String,
        active: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label {
                Text(title)
                    .foregroundStyle(.primary)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(active ? Color.accentColor : Color.secondary)
            }
                .font(GatePassTheme.typeGroupLabel)
                .padding(.horizontal, GatePassTheme.spaceM)
                .frame(height: GatePassTheme.controlHeightCompact)
                .background(active ? Color.accentColor.opacity(0.10) : GatePassTheme.rowBackground, in: Capsule())
                .overlay {
                    Capsule().stroke(active ? Color.accentColor.opacity(0.45) : GatePassTheme.border, lineWidth: GatePassTheme.borderWidth)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
    }

    @ViewBuilder
    private var settingsList: some View {
        if store.catalog == nil && store.isScanning {
            VStack(spacing: GatePassTheme.spaceS) {
                ProgressView()
                Text(gatePassCopy("正在读取系统偏好", "Reading system preferences", language: language))
                    .font(GatePassTheme.typeControl)
                Text(gatePassCopy("首次扫描可能需要几秒钟。", "The first scan may take a few seconds.", language: language))
                    .font(GatePassTheme.typeCaption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if visibleItems.isEmpty {
            GatePassEmptyStateView(
                title: gatePassCopy("没有匹配的偏好", "No matching preferences", language: language),
                systemImage: "slider.horizontal.3",
                description: gatePassCopy("更换分类或重新扫描后再试。", "Try another category or rescan.", language: language)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(visibleItems) { item in
                    SystemPreferenceRow(
                        item: item,
                        desiredOptimized: store.desiredOptimizedIDs.contains(item.id),
                        pending: store.pendingSettingIDs.contains(item.id),
                        language: language
                    ) { enabled in
                        store.setDesiredState(settingID: item.id, optimized: enabled)
                    }
                }
            }
            .listStyle(.inset)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var applyBar: some View {
        HStack(spacing: GatePassTheme.spaceM) {
            if store.pendingCount == 0 {
                Label(
                    gatePassCopy("当前没有待应用的更改", "No pending changes", language: language),
                    systemImage: "checkmark.circle"
                )
                .foregroundStyle(.secondary)
            } else {
                Label {
                    Text(gatePassCopy(
                        "\(store.pendingCount) 项更改等待应用",
                        "\(store.pendingCount) changes pending",
                        language: language
                    ))
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: "circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }

            Spacer()

            Button {
                Task { await store.applyPendingChanges() }
            } label: {
                if store.isApplying {
                    HStack(spacing: GatePassTheme.spaceS) {
                        ProgressView().controlSize(.small)
                        Text(gatePassCopy("正在应用…", "Applying…", language: language))
                    }
                } else {
                    Text(gatePassCopy("应用 \(store.pendingCount) 项更改", "Apply \(store.pendingCount) changes", language: language))
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(height: GatePassTheme.controlHeightLarge)
            .font(GatePassTheme.typeControl)
            .disabled(store.pendingCount == 0 || store.isApplying || store.isScanning)
        }
        .font(GatePassTheme.typeGroupLabel)
        .padding(.horizontal, GatePassTheme.contentBodyPadding)
        .padding(.vertical, GatePassTheme.spaceM)
        .background(.regularMaterial)
    }
}

private struct SystemPreferenceRow: View {
    let item: SystemPreferenceItem
    let desiredOptimized: Bool
    let pending: Bool
    let language: AppLanguage
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: GatePassTheme.spaceM) {
            Image(systemName: item.definition.component.icon)
                .font(GatePassTheme.typeControl)
                .foregroundStyle(Color.accentColor)
                .frame(width: GatePassTheme.spaceXL)

            VStack(alignment: .leading, spacing: GatePassTheme.spaceXS) {
                HStack(spacing: GatePassTheme.spaceS) {
                    Text(item.definition.title(language: language))
                        .font(GatePassTheme.typeControl)
                    statusBadge
                    if item.definition.restartTarget != .none {
                        Text(item.definition.restartTarget.label(language: language))
                            .font(GatePassTheme.typeGroupLabel)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(item.definition.detailedSummary(language: language))
                    .font(GatePassTheme.typeCaption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: GatePassTheme.spaceM)

            if pending {
                Label {
                    Text(gatePassCopy("待应用", "Pending", language: language))
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Color.accentColor)
                }
                .font(GatePassTheme.typeGroupLabel)
            }

            Toggle("", isOn: Binding(get: { desiredOptimized }, set: onToggle))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(item.status == .unavailable)
        }
        .frame(minHeight: GatePassTheme.settingsRowMinHeight)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch item.status {
        case .optimized:
            badge(gatePassCopy("已优化", "Optimized", language: language), color: .green)
        case .recommended:
            if item.definition.riskLevel == .high {
                badge(gatePassCopy("高风险", "High risk", language: language), color: .red)
            } else if item.definition.riskLevel == .caution {
                badge(gatePassCopy("谨慎", "Caution", language: language), color: .orange)
            } else {
                badge(gatePassCopy("推荐", "Recommended", language: language), color: .green)
            }
        case .unavailable:
            let diagnostic = item.diagnostic ?? .stateUnavailable
            badge(diagnostic.title(language: language), color: .secondary)
                .help(diagnostic.detail(for: item.definition, language: language))
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        HStack(spacing: GatePassTheme.spaceXS) {
            Image(systemName: "circle.fill")
                .font(.system(size: GatePassTheme.spaceXS))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(text)
                .foregroundStyle(.primary)
        }
        .font(GatePassTheme.typeGroupLabel)
        .padding(.horizontal, GatePassTheme.spaceS)
        .padding(.vertical, GatePassTheme.spaceXS)
        .background(color.opacity(0.10), in: Capsule())
    }
}

private struct SystemPreferencesResultView: View {
    let result: SystemPreferencesChangeResult
    let language: AppLanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: GatePassTheme.spaceL) {
            HStack {
                Image(systemName: result.failedCount == 0 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.system(size: GatePassTheme.controlHeightCompact))
                    .foregroundStyle(result.failedCount == 0 ? Color.green : Color.orange)
                VStack(alignment: .leading, spacing: GatePassTheme.spaceXS) {
                    Text(gatePassCopy("系统偏好处理完成", "System Preferences completed", language: language))
                        .font(GatePassTheme.typeSectionTitle)
                    Text(gatePassCopy(
                        "已修改 \(result.changedCount) 项，失败 \(result.failedCount) 项。",
                        "Changed \(result.changedCount); failed \(result.failedCount).",
                        language: language
                    ))
                    .font(GatePassTheme.typeCaption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
            }

            List(result.items) { item in
                HStack(spacing: GatePassTheme.spaceM) {
                    Image(systemName: item.verified ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(item.verified ? Color.green : Color.red)
                    Text(MacSystemPreferencesCatalog.byID[item.settingID]?.title(language: language) ?? item.settingID)
                        .font(GatePassTheme.typeBody)
                    Spacer()
                    Text(resultText(item))
                        .font(GatePassTheme.typeCaption)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.inset)
            .frame(maxHeight: 320)

            HStack {
                Spacer()
                Button(gatePassCopy("完成", "Done", language: language)) { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(GatePassTheme.spaceXL)
        .frame(minWidth: 500, idealWidth: 560, maxWidth: 720)
        .frame(minHeight: 260, idealHeight: 360, maxHeight: 620)
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
