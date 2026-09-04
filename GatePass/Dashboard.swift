import SwiftUI
import UniformTypeIdentifiers

private let acceptedDropTypes = [UTType.fileURL]

struct Dashboard: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var updater: GatePassUpdater
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue

    @State private var isDropTargeted = false
    @State private var isFileImporterPresented = false

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            VStack(spacing: GatePassTheme.sectionSpacing) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: GatePassTheme.sectionSpacing) {
                        quarantinePanel
                            .frame(minWidth: 320, idealWidth: 360, maxWidth: .infinity)
                        recentAppsPanel
                            .frame(minWidth: 400, idealWidth: 500, maxWidth: .infinity)
                    }

                    VStack(spacing: GatePassTheme.sectionSpacing) {
                        quarantinePanel
                        recentAppsPanel
                    }
                }

                statusBar
            }
            .padding(GatePassTheme.pageInset)
        }
        .frame(
            minWidth: 0,
            idealWidth: 920,
            maxWidth: .infinity,
            minHeight: 0,
            idealHeight: 680,
            maxHeight: .infinity
        )
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.applicationBundle],
            allowsMultipleSelection: true,
            onCompletion: handleFileImport
        )
        .task {
            appState.refreshRecentApps()
        }
        .animation(
            reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.9),
            value: isDropTargeted
        )
    }

    private var header: some View {
        GatePassPageHeader(
            title: gatePassCopy("App 放行", "App Access", language: language),
            subtitle: gatePassCopy("只为你信任的 App 解除下载隔离", "Remove quarantine from apps you trust", language: language)
        ) {
            if updater.hasNewerGatePassRelease {
                Button {
                    updater.sheet = true
                } label: {
                    Label(gatePassCopy("有可用更新", "Update available", language: language), systemImage: "arrow.down.app")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            GatePassStatusPill(
                text: appState.isGatekeeperAssessmentEnabled
                    ? gatePassCopy("Gatekeeper 已启用", "Gatekeeper on", language: language)
                    : gatePassCopy("Gatekeeper 已关闭", "Gatekeeper off", language: language),
                systemImage: appState.isGatekeeperAssessmentEnabled ? "checkmark.shield.fill" : "exclamationmark.triangle.fill",
                color: appState.isGatekeeperAssessmentEnabled ? .green : .orange
            )
        }
    }

    private var quarantinePanel: some View {
        GatePassPanel(padding: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: GatePassTheme.panelRadius, style: .continuous)
                    .fill(Color.accentColor.opacity(isDropTargeted ? 0.15 : 0.08))

                RoundedRectangle(cornerRadius: GatePassTheme.panelRadius, style: .continuous)
                    .strokeBorder(
                        Color.accentColor.opacity(isDropTargeted ? 0.75 : 0.28),
                        style: StrokeStyle(
                            lineWidth: isDropTargeted ? 2 : 1,
                            dash: isDropTargeted ? [] : [7, 5]
                        )
                    )

                VStack(alignment: .leading, spacing: GatePassTheme.spaceL) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(Color.accentColor)
                        Image(systemName: appState.doneQuarantine ? "checkmark" : "lock.open.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.accentColor.opacity(0.2), radius: 8, y: 4)
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 7) {
                        Text(isDropTargeted
                             ? gatePassCopy("松开即可处理", "Release to process", language: language)
                             : gatePassCopy("解除 App 隔离", "Remove App quarantine", language: language))
                            .font(.title2.weight(.semibold))
                        Text(gatePassCopy(
                            "拖入或选择你确认来源可信的 .app。GatePass 只移除下载隔离属性，不会更改 Gatekeeper 设置。",
                            "Drop or choose an .app you trust. GatePass only removes its quarantine attribute and does not change Gatekeeper settings.",
                            language: language
                        ))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Button {
                        isFileImporterPresented = true
                    } label: {
                        Label(gatePassCopy("选择 App…", "Choose App…", language: language), systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(Color.accentColor)
                    .disabled(appState.isLoading)
                    .keyboardShortcut("o", modifiers: .command)

                    Label(gatePassCopy("支持一次选择多个 App", "You can choose multiple apps", language: language), systemImage: "checkmark.shield")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(GatePassTheme.pageInset)
            }
            .onDrop(
                of: acceptedDropTypes,
                delegate: DropQuarantine(appState: appState, isTargeted: $isDropTargeted)
            )
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 280, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(gatePassCopy("解除 App 隔离", "Remove App quarantine", language: language))
    }

    private var recentAppsPanel: some View {
        GatePassPanel {
            VStack(alignment: .leading, spacing: GatePassTheme.spaceM) {
                HStack(alignment: .center, spacing: GatePassTheme.spaceM) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(gatePassCopy("最近安装", "Recently installed", language: language))
                            .font(.headline)
                        Text(gatePassCopy("过去 7 天 · 可拖入左侧，也可直接处理", "Last 7 days · drag left or process directly", language: language))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        appState.refreshRecentApps()
                    } label: {
                        if appState.isScanningRecentApps {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .buttonStyle(.borderless)
                    .frame(width: 32, height: 32)
                    .disabled(appState.isScanningRecentApps)
                    .help(gatePassCopy("刷新最近安装的 App", "Refresh recently installed apps", language: language))
                    .accessibilityLabel(gatePassCopy("刷新最近安装的 App", "Refresh recently installed apps", language: language))
                }

                Divider()

                Group {
                    if appState.isScanningRecentApps && appState.recentApps.isEmpty {
                        ContentUnavailableViewCompat(
                            icon: "magnifyingglass",
                            title: gatePassCopy("正在扫描", "Scanning", language: language),
                            message: gatePassCopy("正在检查应用程序文件夹…", "Checking your Applications folders…", language: language),
                            showsProgress: true
                        )
                    } else if appState.recentApps.isEmpty {
                        ContentUnavailableViewCompat(
                            icon: "checkmark.circle",
                            title: gatePassCopy("没有新安装的 App", "No newly installed apps", language: language),
                            message: gatePassCopy("已检查 /Applications 和当前用户的 Applications 文件夹。", "Checked /Applications and your user Applications folder.", language: language)
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 4) {
                                ForEach(appState.recentApps) { app in
                                    RecentAppRow(app: app) {
                                        processApplications([app.url])
                                    }
                                    .onDrag {
                                        appDragProvider(for: app)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 280, maxHeight: .infinity)
    }

    private var statusBar: some View {
        HStack(spacing: 9) {
            if appState.isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .accessibilityHidden(true)
            }

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer()
        }
        .frame(minHeight: 22)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var statusText: String {
        if !appState.status.isEmpty {
            return localizedGatePassStatus(appState.status, language: language)
        }
        return gatePassCopy("准备就绪。请只处理你确认来源可信的 App。", "Ready. Only process apps from sources you trust.", language: language)
    }

    private var statusIcon: String {
        if appState.doneQuarantine { return "checkmark.circle.fill" }
        return "info.circle"
    }

    private var statusColor: Color {
        if appState.doneQuarantine { return .green }
        return .secondary
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            processApplications(urls)
        case .failure(let error):
            appState.status = error.localizedDescription
        }
    }

    private func processApplications(_ urls: [URL]) {
        let applications = urls.filter { $0.pathExtension.lowercased() == "app" }
        guard !applications.isEmpty else {
            appState.status = gatePassCopy("请选择 .app 应用程序。", "Choose an .app application.", language: language)
            return
        }

        appState.multiDrop = applications.count > 1
        appState.status = applications.count > 1
            ? gatePassCopy("正在处理 \(applications.count) 个 App…", "Processing \(applications.count) apps…", language: language)
            : gatePassCopy("正在移除 App 的隔离标记…", "Removing the App quarantine attribute…", language: language)
        appState.isLoading = true

        Task {
            for application in applications {
                await removeQuarantine(path: application.path, appState: appState)
            }
            await MainActor.run {
                appState.refreshRecentApps()
            }
        }
    }
}

private func appDragProvider(for app: RecentApp) -> NSItemProvider {
    let provider = NSItemProvider()
    provider.registerDataRepresentation(
        forTypeIdentifier: UTType.fileURL.identifier,
        visibility: .all
    ) { completion in
        completion(app.url.dataRepresentation, nil)
        return nil
    }
    return provider
}

private struct RecentAppRow: View {
    let app: RecentApp
    let onProcess: () -> Void

    var body: some View {
        HStack(spacing: 11) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
                .resizable()
                .interpolation(.high)
                .frame(width: 34, height: 34)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                Text(gatePassCopy(
                    "安装于 \(app.installedAt.formatted(date: .abbreviated, time: .omitted))",
                    "Installed \(app.installedAt.formatted(date: .abbreviated, time: .omitted))",
                    language: language
                ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            Button(gatePassCopy("解除", "Remove", language: language)) {
                onProcess()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help(gatePassCopy("移除 \(app.name) 的下载隔离属性", "Remove the quarantine attribute from \(app.name)", language: language))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(GatePassTheme.rowBackground, in: RoundedRectangle(cornerRadius: GatePassTheme.rowRadius, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityLabel(gatePassCopy(
            "\(app.name)，安装于 \(app.installedAt.formatted(date: .long, time: .omitted))",
            "\(app.name), installed on \(app.installedAt.formatted(date: .long, time: .omitted))",
            language: language
        ))
    }

    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }
}

private struct ContentUnavailableViewCompat: View {
    let icon: String
    let title: String
    let message: String
    var showsProgress = false

    var body: some View {
        VStack(spacing: 9) {
            if showsProgress {
                ProgressView()
                    .controlSize(.regular)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(.callout.weight(.semibold))
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}
