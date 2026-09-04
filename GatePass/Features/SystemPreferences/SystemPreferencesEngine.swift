import Foundation
import SwiftUI

enum SystemPreferencePresetEngine {
    private static let smartExtras: Set<String> = [
        "macos.finder.disable-extension-warning",
        "macos.finder.default-list-view",
        "macos.keyboard.full-navigation",
        "macos.text.disable-auto-correct",
        "macos.text.disable-smart-quotes",
        "macos.text.disable-smart-dashes",
        "macos.text.disable-auto-capitalization",
        "macos.text.disable-period-substitution",
        "macos.dock.scroll-to-expose"
    ]

    static func desiredIDs(mode: SystemPreferenceMode, catalog: SystemPreferencesCatalog) -> Set<String> {
        var result = catalog.optimizedIDs
        guard mode != .unchanged && mode != .manual else { return result }

        for item in catalog.items where item.status == .recommended && item.definition.riskLevel != .high {
            guard SystemPreferenceMetadata.isEligibleForAutomaticPreset(item.id) else { continue }
            let selectedByDefault = item.definition.selectionKind == .oneClick
            let smart = smartExtras.contains(item.id)
            let focused: Bool
            switch mode {
            case .performance:
                focused = item.definition.category == .performance || item.id == "macos.keyboard.disable-press-and-hold"
            case .privacy:
                focused = item.definition.category == .privacy
            default:
                focused = false
            }
            if selectedByDefault || smart || focused { result.insert(item.id) }
        }
        return result
    }
}

struct SystemPreferencesScanner {
    let definitions: [SystemPreferenceDefinition]
    let client: SystemDefaultsAccess

    func scan(recovery: SystemPreferencesRecoveryDocument?) async -> SystemPreferencesCatalog {
        let definitions = self.definitions
        let client = self.client
        return await Task.detached(priority: .userInitiated) {
            let started = Date()
            let deadline = started.addingTimeInterval(6)
            let recoveryByID = Dictionary(uniqueKeysWithValues: (recovery?.items ?? []).map { ($0.settingID, $0) })
            let osVersion = ProcessInfo.processInfo.operatingSystemVersion
            var items: [SystemPreferenceItem] = []

            for definition in definitions {
                guard definition.isSupported(on: osVersion) else {
                    items.append(SystemPreferenceItem(
                        definition: definition,
                        currentValue: .missing,
                        status: .unavailable,
                        diagnostic: .unsupported,
                        restoreAvailable: false
                    ))
                    continue
                }

                let remaining = deadline.timeIntervalSinceNow
                guard remaining > 0 else {
                    items.append(SystemPreferenceItem(
                        definition: definition,
                        currentValue: .missing,
                        status: .unavailable,
                        diagnostic: .stateUnavailable,
                        restoreAvailable: false
                    ))
                    continue
                }

                do {
                    let current = try client.read(definition, timeout: min(2, remaining))
                    let status: SystemPreferenceStatus = current == definition.recommendedValue ? .optimized : .recommended
                    let restoreAvailable = recoveryByID[definition.id]?.optimizedValue == current
                    items.append(SystemPreferenceItem(
                        definition: definition,
                        currentValue: current,
                        status: status,
                        diagnostic: nil,
                        restoreAvailable: restoreAvailable
                    ))
                } catch SystemDefaultsClientError.accessDenied {
                    items.append(SystemPreferenceItem(
                        definition: definition,
                        currentValue: .missing,
                        status: .unavailable,
                        diagnostic: .accessDenied,
                        restoreAvailable: false
                    ))
                } catch {
                    items.append(SystemPreferenceItem(
                        definition: definition,
                        currentValue: .missing,
                        status: .unavailable,
                        diagnostic: .stateUnavailable,
                        restoreAvailable: false
                    ))
                }
            }

            return SystemPreferencesCatalog(
                scanID: UUID(),
                revision: MacSystemPreferencesCatalog.revision,
                scannedAt: Date(),
                elapsed: Date().timeIntervalSince(started),
                items: items,
                recoveryAvailable: recovery?.items.isEmpty == false
            )
        }.value
    }
}

struct SystemPreferencesPlanner {
    private let ttl: TimeInterval = 5 * 60

    func prepare(
        catalog: SystemPreferencesCatalog,
        desiredOptimizedIDs: Set<String>,
        recovery: SystemPreferencesRecoveryDocument?
    ) -> SystemPreferencesChangePlan {
        let recoveryByID = Dictionary(uniqueKeysWithValues: (recovery?.items ?? []).map { ($0.settingID, $0) })
        var items: [SystemPreferenceChangePlanItem] = []
        var skipped: [SystemPreferenceSkippedItem] = []

        for item in catalog.items {
            let desiredOptimized = desiredOptimizedIDs.contains(item.id)
            let currentlyOptimized = item.status == .optimized
            guard desiredOptimized != currentlyOptimized else { continue }

            guard item.status != .unavailable else {
                let reason: SystemPreferenceSkipReason = item.diagnostic == .unsupported ? .unsupported : .stateUnavailable
                skipped.append(.init(settingID: item.id, reason: reason))
                continue
            }

            let target: SystemPreferenceTargetState = desiredOptimized ? .optimized : .systemDefault
            let desiredValue: SystemPreferenceValue
            if target == .optimized {
                desiredValue = item.definition.recommendedValue
            } else if let recoveryItem = recoveryByID[item.id], recoveryItem.optimizedValue == item.currentValue {
                desiredValue = recoveryItem.originalValue
            } else {
                desiredValue = item.definition.disabledValue ?? item.definition.defaultValue
            }

            items.append(SystemPreferenceChangePlanItem(
                settingID: item.id,
                target: target,
                expectedValue: item.currentValue,
                desiredValue: desiredValue,
                requiresRestart: item.definition.requiresRestart,
                riskLevel: item.definition.riskLevel
            ))
        }

        return makePlan(catalog: catalog, items: items, skipped: skipped)
    }

    func prepareRecovery(
        catalog: SystemPreferencesCatalog,
        recovery: SystemPreferencesRecoveryDocument
    ) -> SystemPreferencesChangePlan {
        let catalogByID = Dictionary(uniqueKeysWithValues: catalog.items.map { ($0.id, $0) })
        var items: [SystemPreferenceChangePlanItem] = []
        var skipped: [SystemPreferenceSkippedItem] = []

        for recoveryItem in recovery.items {
            guard let current = catalogByID[recoveryItem.settingID] else {
                skipped.append(.init(settingID: recoveryItem.settingID, reason: .settingMissing))
                continue
            }
            guard current.status != .unavailable else {
                let reason: SystemPreferenceSkipReason = current.diagnostic == .unsupported ? .unsupported : .stateUnavailable
                skipped.append(.init(settingID: recoveryItem.settingID, reason: reason))
                continue
            }
            if current.currentValue == recoveryItem.originalValue { continue }
            guard current.currentValue == recoveryItem.optimizedValue else {
                skipped.append(.init(settingID: recoveryItem.settingID, reason: .settingChanged))
                continue
            }
            items.append(SystemPreferenceChangePlanItem(
                settingID: recoveryItem.settingID,
                target: .systemDefault,
                expectedValue: current.currentValue,
                desiredValue: recoveryItem.originalValue,
                requiresRestart: current.definition.requiresRestart,
                riskLevel: current.definition.riskLevel
            ))
        }

        return makePlan(catalog: catalog, items: items, skipped: skipped)
    }

    private func makePlan(
        catalog: SystemPreferencesCatalog,
        items: [SystemPreferenceChangePlanItem],
        skipped: [SystemPreferenceSkippedItem]
    ) -> SystemPreferencesChangePlan {
        let now = Date()
        return SystemPreferencesChangePlan(
            id: UUID(),
            scanID: catalog.scanID,
            catalogRevision: catalog.revision,
            createdAt: now,
            expiresAt: now.addingTimeInterval(ttl),
            items: items,
            skippedItems: skipped
        )
    }
}

actor SystemPreferencesRecoveryStore {
    private let fileURL: URL

    init(rootURL: URL? = nil) {
        let root = rootURL ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GatePass", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        fileURL = root.appendingPathComponent("system-preferences-recovery.json")
    }

    func load() -> SystemPreferencesRecoveryDocument? {
        guard let data = try? Data(contentsOf: fileURL), data.count <= 1_048_576 else { return nil }
        guard let document = try? JSONDecoder().decode(SystemPreferencesRecoveryDocument.self, from: data),
              document.schemaVersion == SystemPreferencesRecoveryDocument.currentSchemaVersion else { return nil }
        return document
    }

    func save(_ document: SystemPreferencesRecoveryDocument) throws {
        let data = try JSONEncoder().encode(document)
        guard data.count <= 1_048_576 else { throw StoreError.tooLarge }
        try data.write(to: fileURL, options: .atomic)
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    enum StoreError: Error { case tooLarge }
}

actor SystemPreferencesHistoryStore {
    private let fileURL: URL
    private let maximumRecords = 200

    init(rootURL: URL? = nil) {
        let root = rootURL ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GatePass", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        fileURL = root.appendingPathComponent("system-preferences-history.json")
    }

    func append(_ result: SystemPreferencesChangeResult) throws {
        var records = load()
        records.insert(result, at: 0)
        records = Array(records.prefix(maximumRecords))
        let data = try JSONEncoder().encode(records)
        try data.write(to: fileURL, options: .atomic)
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    func load() -> [SystemPreferencesChangeResult] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([SystemPreferencesChangeResult].self, from: data)) ?? []
    }
}

struct SystemPreferencesRefresher {
    static let finderRefreshSettingIDs: Set<String> = [
        "macos.finder.show-hidden-files",
        "macos.finder.open-folders-in-tabs",
        "macos.finder.auto-size-columns",
        "macos.desktop.hide-all-icons"
    ]

    static let dockRefreshSettingIDs: Set<String> = [
        "macos.dock.lock-contents",
        "macos.dock.lock-size"
    ]

    static let systemUIRefreshSettingIDs: Set<String> = [
        "macos.menubar.flash-time-separators"
    ]

    func refreshIfNeeded(changedSettingIDs: Set<String>) async {
        let refreshFinder = !changedSettingIDs.isDisjoint(with: Self.finderRefreshSettingIDs)
        let refreshDock = !changedSettingIDs.isDisjoint(with: Self.dockRefreshSettingIDs)
        let refreshSystemUI = !changedSettingIDs.isDisjoint(with: Self.systemUIRefreshSettingIDs)
        guard refreshFinder || refreshDock || refreshSystemUI else { return }

        await Task.detached(priority: .utility) {
            if refreshFinder { Self.killall("Finder") }
            if refreshDock { Self.killall("Dock") }
            if refreshSystemUI { Self.killall("SystemUIServer") }
        }.value
    }

    private static func killall(_ processName: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = [processName]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }
}

enum SystemPreferencesExecutorError: Error, LocalizedError {
    case planExpired
    var errorDescription: String? { "系统偏好变更计划已过期，请重新扫描后再试。" }
}

struct SystemPreferencesExecutor {
    let definitions: [String: SystemPreferenceDefinition]
    let client: SystemDefaultsAccess
    let recoveryStore: SystemPreferencesRecoveryStore
    let refresher: SystemPreferencesRefresher

    func execute(
        _ plan: SystemPreferencesChangePlan,
        previousRecovery: SystemPreferencesRecoveryDocument?
    ) async throws -> SystemPreferencesChangeResult {
        guard Date() <= plan.expiresAt else { throw SystemPreferencesExecutorError.planExpired }

        let preflightRecovery = mergedRecovery(existing: previousRecovery, plan: plan)
        if !preflightRecovery.items.isEmpty { try await recoveryStore.save(preflightRecovery) }

        let runner = self
        let results = await Task.detached(priority: .userInitiated) {
            plan.items.map { runner.executeItem($0) }
        }.value

        let reconciled = reconciledRecovery(
            preflightRecovery,
            previousIDs: Set(previousRecovery?.items.map(\.settingID) ?? []),
            plan: plan,
            results: results
        )
        if reconciled.items.isEmpty { await recoveryStore.clear() }
        else { try await recoveryStore.save(reconciled) }

        let changed = Set(results.filter { $0.outcome == .changed && $0.verified }.map(\.settingID))
        await refresher.refreshIfNeeded(changedSettingIDs: changed)

        return SystemPreferencesChangeResult(id: UUID(), planID: plan.id, createdAt: Date(), items: results)
    }

    private func executeItem(_ item: SystemPreferenceChangePlanItem) -> SystemPreferenceChangeItemResult {
        guard let definition = definitions[item.settingID] else { return failed(item, .unsupported) }
        do {
            let before = try client.read(definition, timeout: 2)
            if before == item.desiredValue {
                return .init(settingID: item.settingID, outcome: .unchanged, verified: true, failureReason: nil)
            }
            guard before == item.expectedValue else { return failed(item, .settingChanged) }
            try client.write(item.desiredValue, definition: definition, timeout: 2)
            let after = try client.read(definition, timeout: 2)
            guard after == item.desiredValue else { return failed(item, .verificationFailed) }
            return .init(settingID: item.settingID, outcome: .changed, verified: true, failureReason: nil)
        } catch SystemDefaultsClientError.accessDenied {
            return failed(item, .permissionDenied)
        } catch {
            return failed(item, .platformFailure)
        }
    }

    private func failed(_ item: SystemPreferenceChangePlanItem, _ reason: SystemPreferenceChangeFailureReason) -> SystemPreferenceChangeItemResult {
        .init(settingID: item.settingID, outcome: .failed, verified: false, failureReason: reason)
    }

    private func mergedRecovery(
        existing: SystemPreferencesRecoveryDocument?,
        plan: SystemPreferencesChangePlan
    ) -> SystemPreferencesRecoveryDocument {
        var byID = Dictionary(uniqueKeysWithValues: (existing?.items ?? []).map { ($0.settingID, $0) })
        for item in plan.items where item.target == .optimized && byID[item.settingID] == nil {
            byID[item.settingID] = SystemPreferencesRecoveryItem(
                settingID: item.settingID,
                originalValue: item.expectedValue,
                optimizedValue: item.desiredValue
            )
        }
        return SystemPreferencesRecoveryDocument(
            schemaVersion: SystemPreferencesRecoveryDocument.currentSchemaVersion,
            recoveryID: existing?.recoveryID ?? UUID(),
            createdAt: existing?.createdAt ?? Date(),
            items: Array(byID.values).sorted { $0.settingID < $1.settingID }
        )
    }

    private func reconciledRecovery(
        _ document: SystemPreferencesRecoveryDocument,
        previousIDs: Set<String>,
        plan: SystemPreferencesChangePlan,
        results: [SystemPreferenceChangeItemResult]
    ) -> SystemPreferencesRecoveryDocument {
        var copy = document
        let resultByID = Dictionary(uniqueKeysWithValues: results.map { ($0.settingID, $0) })
        let planByID = Dictionary(uniqueKeysWithValues: plan.items.map { ($0.settingID, $0) })
        copy.items.removeAll { recoveryItem in
            guard let planItem = planByID[recoveryItem.settingID], let result = resultByID[recoveryItem.settingID] else { return false }
            if planItem.target == .systemDefault && result.verified { return true }
            if planItem.target == .optimized && !previousIDs.contains(recoveryItem.settingID) {
                switch result.failureReason {
                case .settingChanged?, .permissionDenied?, .unsupported?: return true
                default: return false
                }
            }
            return false
        }
        return copy
    }
}

@MainActor
final class SystemPreferencesStore: ObservableObject {
    @Published private(set) var catalog: SystemPreferencesCatalog?
    @Published var mode: SystemPreferenceMode = .smart
    @Published private(set) var desiredOptimizedIDs: Set<String> = []
    @Published var selectedCategory: SystemPreferenceCategory?
    @Published var showPendingOnly = false
    @Published private(set) var isScanning = false
    @Published private(set) var isApplying = false
    @Published var lastResult: SystemPreferencesChangeResult?
    @Published var errorMessage: String?
    @Published var pendingRiskPlan: SystemPreferencesChangePlan?

    private let scanner: SystemPreferencesScanner
    private let planner: SystemPreferencesPlanner
    private let executor: SystemPreferencesExecutor
    private let recoveryStore: SystemPreferencesRecoveryStore
    private let historyStore: SystemPreferencesHistoryStore
    private var initializedDraft = false

    static func live() -> SystemPreferencesStore {
        let definitions = MacSystemPreferencesCatalog.all
        let client = SystemDefaultsClient()
        let recovery = SystemPreferencesRecoveryStore()
        let history = SystemPreferencesHistoryStore()
        return SystemPreferencesStore(
            scanner: SystemPreferencesScanner(definitions: definitions, client: client),
            planner: SystemPreferencesPlanner(),
            executor: SystemPreferencesExecutor(
                definitions: Dictionary(uniqueKeysWithValues: definitions.map { ($0.id, $0) }),
                client: client,
                recoveryStore: recovery,
                refresher: SystemPreferencesRefresher()
            ),
            recoveryStore: recovery,
            historyStore: history
        )
    }

    init(
        scanner: SystemPreferencesScanner,
        planner: SystemPreferencesPlanner,
        executor: SystemPreferencesExecutor,
        recoveryStore: SystemPreferencesRecoveryStore,
        historyStore: SystemPreferencesHistoryStore
    ) {
        self.scanner = scanner
        self.planner = planner
        self.executor = executor
        self.recoveryStore = recoveryStore
        self.historyStore = historyStore
    }

    var pendingSettingIDs: Set<String> {
        guard let catalog else { return [] }
        return Set(catalog.items.filter { item in
            item.status != .unavailable && desiredOptimizedIDs.contains(item.id) != (item.status == .optimized)
        }.map(\.id))
    }

    var pendingCount: Int { pendingSettingIDs.count }

    var filteredItems: [SystemPreferenceItem] {
        guard let catalog else { return [] }
        return catalog.items.filter { item in
            if showPendingOnly && !pendingSettingIDs.contains(item.id) { return false }
            if let selectedCategory, item.definition.category != selectedCategory { return false }
            return true
        }
    }

    func scan() async {
        guard !isScanning && !isApplying else { return }
        isScanning = true
        defer { isScanning = false }
        let recovery = await recoveryStore.load()
        let fresh = await scanner.scan(recovery: recovery)
        catalog = fresh
        if !initializedDraft {
            desiredOptimizedIDs = SystemPreferencePresetEngine.desiredIDs(mode: .smart, catalog: fresh)
            mode = .smart
            initializedDraft = true
        } else {
            desiredOptimizedIDs.formIntersection(Set(fresh.items.map(\.id)))
        }
    }

    func selectMode(_ newMode: SystemPreferenceMode) {
        guard let catalog, newMode != .manual else { return }
        mode = newMode
        desiredOptimizedIDs = SystemPreferencePresetEngine.desiredIDs(mode: newMode, catalog: catalog)
    }

    func setDesiredState(settingID: String, optimized: Bool) {
        mode = .manual
        if optimized { desiredOptimizedIDs.insert(settingID) }
        else { desiredOptimizedIDs.remove(settingID) }
    }

    func applyPendingChanges() async {
        guard !isApplying, let catalog else { return }
        let recovery = await recoveryStore.load()
        let plan = planner.prepare(catalog: catalog, desiredOptimizedIDs: desiredOptimizedIDs, recovery: recovery)
        guard !plan.items.isEmpty else { return }
        if !plan.highRiskItems.isEmpty {
            pendingRiskPlan = plan
            return
        }
        await execute(plan, previousRecovery: recovery)
    }

    func confirmRiskPlan() async {
        guard let plan = pendingRiskPlan else { return }
        pendingRiskPlan = nil
        let recovery = await recoveryStore.load()
        await execute(plan, previousRecovery: recovery)
    }

    func restorePreviousOptimization() async {
        guard !isApplying, let recovery = await recoveryStore.load() else { return }
        isScanning = true
        let fresh = await scanner.scan(recovery: recovery)
        isScanning = false
        catalog = fresh
        let plan = planner.prepareRecovery(catalog: fresh, recovery: recovery)
        guard !plan.items.isEmpty else {
            if recovery.items.allSatisfy({ item in
                fresh.items.first(where: { $0.id == item.settingID })?.currentValue == item.originalValue
            }) {
                await recoveryStore.clear()
                catalog = await scanner.scan(recovery: nil)
            }
            return
        }
        await execute(plan, previousRecovery: recovery)
    }

    private func execute(_ plan: SystemPreferencesChangePlan, previousRecovery: SystemPreferencesRecoveryDocument?) async {
        guard !isApplying else { return }
        isApplying = true
        defer { isApplying = false }
        do {
            let result = try await executor.execute(plan, previousRecovery: previousRecovery)
            lastResult = result
            try? await historyStore.append(result)
            let recovery = await recoveryStore.load()
            let fresh = await scanner.scan(recovery: recovery)
            catalog = fresh
            desiredOptimizedIDs = Set(fresh.items.filter { $0.status == .optimized }.map(\.id))
            mode = .manual
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
