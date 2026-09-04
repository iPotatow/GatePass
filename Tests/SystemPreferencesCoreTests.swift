import Foundation
import SwiftUI

enum AppLanguage: String {
    case system
    case zhHans
    case english
}

func gatePassCopy(_ zhHans: String, _ english: String, language: AppLanguage) -> String {
    language == .english ? english : zhHans
}

enum SystemPreferenceMode: String, CaseIterable {
    case unchanged
    case smart
    case performance
    case privacy
    case manual
}

enum TestFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message): return message
        }
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw TestFailure.failed(message) }
}

final class FakeDefaultsClient: SystemDefaultsAccess, @unchecked Sendable {
    enum Behavior: Equatable {
        case normal
        case ignoreWrites
    }

    private let lock = NSLock()
    private var values: [String: SystemPreferenceValue]
    private let deniedIDs: Set<String>
    private let behavior: Behavior

    init(
        values: [String: SystemPreferenceValue],
        deniedIDs: Set<String> = [],
        behavior: Behavior = .normal
    ) {
        self.values = values
        self.deniedIDs = deniedIDs
        self.behavior = behavior
    }

    func read(_ definition: SystemPreferenceDefinition, timeout: TimeInterval) throws -> SystemPreferenceValue {
        lock.lock()
        defer { lock.unlock() }
        if deniedIDs.contains(definition.id) { throw SystemDefaultsClientError.accessDenied }
        return values[definition.id] ?? .missing
    }

    func write(
        _ value: SystemPreferenceValue,
        definition: SystemPreferenceDefinition,
        timeout: TimeInterval
    ) throws {
        lock.lock()
        defer { lock.unlock() }
        if deniedIDs.contains(definition.id) { throw SystemDefaultsClientError.accessDenied }
        if behavior == .normal { values[definition.id] = value }
    }

    func set(_ value: SystemPreferenceValue, for id: String) {
        lock.lock()
        values[id] = value
        lock.unlock()
    }
}

@main
struct SystemPreferencesCoreTests {
    static func main() async {
        do {
            try testCatalogIntegrity()
            try testMetadataCoverage()
            try testCompatibilityMetadata()
            try testMacOSDefaultsSupplement()
            try testBehaviorEvidencePolicy()
            try testPresetEngine()
            try testPlannerAndTTL()
            try await testScannerUnsupportedGuard()
            try await testExecutorStaleState()
            try await testExecutorVerificationFailure()
            try await testRecoveryRoundTrip()
            try await testPartialFailure()
            try await testHistoryPersistence()
            try testRealDefaultsClientRoundTrip()
            print("✅ System Preferences core tests passed")
        } catch {
            fputs("❌ \(error)\n", stderr)
            exit(1)
        }
    }

    static func testCatalogIntegrity() throws {
        let catalog = MacSystemPreferencesCatalog.all
        let ids = catalog.map(\.id)

        try expect(catalog.count == 60, "Catalog must contain exactly 60 preferences, got \(catalog.count)")
        try expect(Set(ids).count == ids.count, "Catalog IDs must be unique")
        try expect(catalog.allSatisfy { $0.id.hasPrefix("macos.") }, "Every catalog ID must use the macos. namespace")
        try expect(catalog.allSatisfy { !$0.domain.isEmpty && !$0.key.isEmpty }, "Every preference must have a domain and key")
        let removedComponents: Set<SystemPreferenceComponent> = [
            .safari, .windows, .missionControl, .activityMonitor, .appStore, .timeMachine,
            .textEdit, .photos, .printing, .sharing, .privacy, .sound, .security
        ]
        try expect(catalog.allSatisfy { !removedComponents.contains($0.component) },
                   "Removed System Preferences components must not remain in the catalog")

        for item in catalog {
            switch (item.valueType, item.recommendedValue) {
            case (.boolean, .bool), (.integer, .int), (.floatingPoint, .double), (.text, .text):
                break
            default:
                throw TestFailure.failed("Recommended value type mismatch for \(item.id)")
            }
        }
    }

    static func testMetadataCoverage() throws {
        let ids = Set(MacSystemPreferencesCatalog.all.map(\.id))
        let metadataIDs = Set(SystemPreferenceMetadata.descriptions.keys)

        try expect(metadataIDs == ids, "Detailed descriptions must cover the same 60 IDs as the catalog")
        try expect(SystemPreferenceMetadata.descriptions.count == 60, "Detailed descriptions must contain 60 entries")
        try expect(SystemPreferenceMetadata.descriptions.values.allSatisfy {
            !$0.zh.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !$0.en.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }, "Every preference must have non-empty Chinese and English descriptions")

        let genericChinese = Set([
            "调整 macOS 行为以提升响应速度。",
            "调整 macOS 日常使用偏好以提高效率。",
            "调整与隐私、安全和数据暴露相关的系统偏好。",
            "调整文件与存储相关的系统偏好。",
            "调整窗口、Dock 或界面显示行为。"
        ])
        try expect(SystemPreferenceMetadata.descriptions.values.allSatisfy { !genericChinese.contains($0.zh) },
                   "Generic category placeholder descriptions must not remain")
    }

    static func testCompatibilityMetadata() throws {
        let inline = try unwrap(MacSystemPreferencesCatalog.byID["macos.text.disable-inline-predictions"], "Missing inline prediction definition")
        let finder = try unwrap(MacSystemPreferencesCatalog.byID["macos.finder.show-path-bar"], "Missing Finder path definition")

        try expect(!inline.isSupported(on: .init(majorVersion: 13, minorVersion: 6, patchVersion: 0)),
                   "Inline predictions must be guarded on macOS 13")
        try expect(inline.isSupported(on: .init(majorVersion: 14, minorVersion: 0, patchVersion: 0)),
                   "Inline predictions must be supported from macOS 14")
        try expect(finder.isSupported(on: .init(majorVersion: 13, minorVersion: 0, patchVersion: 0)),
                   "Finder path bar should be supported on GatePass minimum macOS 13")

        try expect(finder.restartTarget == .finder, "Finder restart target should be Finder")
        let dock = try unwrap(MacSystemPreferencesCatalog.byID["macos.dock.auto-hide"], "Missing Dock definition")
        try expect(dock.restartTarget == .dock, "Dock restart target should be Dock")

        let contentsLock = try unwrap(MacSystemPreferencesCatalog.byID["macos.dock.lock-contents"], "Missing Dock contents lock")
        let sizeLock = try unwrap(MacSystemPreferencesCatalog.byID["macos.dock.lock-size"], "Missing Dock size lock")
        try expect(contentsLock.domain == "com.apple.dock" && contentsLock.key == "contents-immutable",
                   "Dock contents lock must use com.apple.dock contents-immutable")
        try expect(sizeLock.domain == "com.apple.dock" && sizeLock.key == "size-immutable",
                   "Dock size lock must use com.apple.dock size-immutable")
        try expect(contentsLock.recommendedValue == .bool(true) && contentsLock.disabledValue == .bool(false),
                   "Dock contents lock must map enabled/disabled to true/false")
        try expect(sizeLock.recommendedValue == .bool(true) && sizeLock.disabledValue == .bool(false),
                   "Dock size lock must map enabled/disabled to true/false")
        try expect(contentsLock.restartTarget == .dock && sizeLock.restartTarget == .dock,
                   "Dock lock preferences must advertise Dock relaunch")
        try expect(SystemPreferencesRefresher.dockRefreshSettingIDs.contains(contentsLock.id) &&
                   SystemPreferencesRefresher.dockRefreshSettingIDs.contains(sizeLock.id),
                   "Dock lock preferences must trigger killall Dock after verified changes")
    }

    static func testMacOSDefaultsSupplement() throws {
        let openTabs = try unwrap(MacSystemPreferencesCatalog.byID["macos.finder.open-folders-in-tabs"], "Missing FinderSpawnTab definition")
        try expect(openTabs.domain == "com.apple.finder" && openTabs.key == "FinderSpawnTab", "Finder tabs mapping must match macos-defaults.com")
        try expect(openTabs.minimumMacOSMajorVersion == 14, "FinderSpawnTab should be guarded from macOS 14")

        let columns = try unwrap(MacSystemPreferencesCatalog.byID["macos.finder.auto-size-columns"], "Missing Finder column auto sizing definition")
        try expect(columns.minimumMacOSMajorVersion == 26, "Finder column auto sizing should be Tahoe-only until older systems are evidenced")

        let mouse = try unwrap(MacSystemPreferencesCatalog.byID["macos.mouse.disable-acceleration"], "Missing mouse acceleration definition")
        try expect(mouse.domain == "NSGlobalDomain" && mouse.key == "com.apple.mouse.linear", "Mouse acceleration mapping must match source")
        try expect(mouse.restartTarget == .mac, "Mouse acceleration requires a Mac restart")

        let delay = try unwrap(MacSystemPreferencesCatalog.byID["macos.dock.remove-auto-hide-delay"], "Missing Dock delay definition")
        let animation = try unwrap(MacSystemPreferencesCatalog.byID["macos.dock.fast-auto-hide-animation"], "Missing Dock animation definition")
        try expect(delay.valueType == .floatingPoint && delay.recommendedValue == .double(0), "Dock autohide delay must use -float semantics")
        try expect(animation.valueType == .floatingPoint && animation.recommendedValue == .double(0), "Dock autohide animation must use -float semantics")

        let language = try unwrap(MacSystemPreferencesCatalog.byID["macos.keyboard.hide-language-indicator"], "Missing language indicator definition")
        try expect(language.domain == "kCFPreferencesAnyApplication" && language.key == "TSMLanguageIndicatorEnabled", "Language indicator mapping must match source")

        try expect(SystemPreferencesRefresher.finderRefreshSettingIDs.contains("macos.finder.open-folders-in-tabs"), "Finder supplement should refresh Finder")
        try expect(SystemPreferencesRefresher.systemUIRefreshSettingIDs.contains("macos.menubar.flash-time-separators"), "Menu bar supplement should refresh SystemUIServer")
    }

    static func testBehaviorEvidencePolicy() throws {
        let removedBroken = [
            "macos.finder.folders-first-on-desktop",
            "macos.safari.show-full-url",
            "macos.textedit.plain-text-default"
        ]
        try expect(removedBroken.allSatisfy { MacSystemPreferencesCatalog.byID[$0] == nil },
                   "Keys explicitly marked broken by macos-defaults.com must not remain in the catalog")

        let expectedExcluded: Set<String> = [
            "macos.finder.show-hard-drives-on-desktop",
            "macos.finder.show-external-drives-on-desktop",
            "macos.finder.show-removable-media-on-desktop",
            "macos.dock.show-only-open-apps",
            "macos.documents.save-locally",
            "macos.keyboard.disable-press-and-hold",
            "macos.dock.enable-spring-loading"
        ]
        try expect(SystemPreferenceMetadata.automaticPresetExcludedIDs == expectedExcluded,
                   "Site-marked uncertain preferences must remain excluded from automatic presets")

        let items = expectedExcluded.compactMap { id -> SystemPreferenceItem? in
            guard let definition = MacSystemPreferencesCatalog.byID[id] else { return nil }
            return SystemPreferenceItem(
                definition: definition,
                currentValue: definition.defaultValue,
                status: .recommended,
                diagnostic: nil,
                restoreAvailable: false
            )
        }
        try expect(items.count == expectedExcluded.count, "Every uncertain preference should remain available manually")
        let catalog = SystemPreferencesCatalog(
            scanID: UUID(), revision: "evidence-test", scannedAt: Date(), elapsed: 0,
            items: items, recoveryAvailable: false
        )
        for mode in [SystemPreferenceMode.smart, .performance, .privacy] {
            let desired = SystemPreferencePresetEngine.desiredIDs(mode: mode, catalog: catalog)
            try expect(desired.isDisjoint(with: expectedExcluded),
                       "Uncertain behavior preferences must not be auto-selected in \(mode.rawValue)")
        }
    }

    static func testPresetEngine() throws {
        let definitions = [
            try unwrap(MacSystemPreferencesCatalog.byID["macos.finder.show-file-extensions"], "Missing one-click definition"),
            try unwrap(MacSystemPreferencesCatalog.byID["macos.keyboard.fast-key-repeat"], "Missing performance definition")
        ]

        let items = definitions.map {
            SystemPreferenceItem(
                definition: $0,
                currentValue: $0.defaultValue,
                status: .recommended,
                diagnostic: nil,
                restoreAvailable: false
            )
        }
        let catalog = SystemPreferencesCatalog(
            scanID: UUID(),
            revision: "test",
            scannedAt: Date(),
            elapsed: 0,
            items: items,
            recoveryAvailable: false
        )

        let smart = SystemPreferencePresetEngine.desiredIDs(mode: .smart, catalog: catalog)
        try expect(smart.contains("macos.finder.show-file-extensions"), "Smart preset should include one-click recommendations")

        let performance = SystemPreferencePresetEngine.desiredIDs(mode: .performance, catalog: catalog)
        try expect(performance.contains("macos.keyboard.fast-key-repeat"), "Performance preset should include performance preferences")
    }

    static func testPlannerAndTTL() throws {
        let definition = try unwrap(MacSystemPreferencesCatalog.byID["macos.finder.show-path-bar"], "Missing Finder path definition")
        let item = SystemPreferenceItem(
            definition: definition,
            currentValue: .bool(false),
            status: .recommended,
            diagnostic: nil,
            restoreAvailable: false
        )
        let catalog = SystemPreferencesCatalog(
            scanID: UUID(),
            revision: "test",
            scannedAt: Date(),
            elapsed: 0,
            items: [item],
            recoveryAvailable: false
        )

        let plan = SystemPreferencesPlanner().prepare(
            catalog: catalog,
            desiredOptimizedIDs: [definition.id],
            recovery: nil
        )

        try expect(plan.items.count == 1, "Planner should create one pending change")
        try expect(plan.items[0].expectedValue == .bool(false), "Planner expected value must reflect scan state")
        try expect(plan.items[0].desiredValue == .bool(true), "Planner desired value must use recommendation")
        let ttl = plan.expiresAt.timeIntervalSince(plan.createdAt)
        try expect(abs(ttl - 300) < 0.5, "Change plan TTL must remain 5 minutes")
    }

    static func testScannerUnsupportedGuard() async throws {
        let definition = try unwrap(MacSystemPreferencesCatalog.byID["macos.text.disable-inline-predictions"], "Missing inline prediction definition")

        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 13 {
            let client = FakeDefaultsClient(values: [definition.id: .bool(true)])
            let catalog = await SystemPreferencesScanner(definitions: [definition], client: client).scan(recovery: nil)
            try expect(catalog.items.first?.status == .unavailable, "Unsupported preference must be unavailable on macOS 13")
            try expect(catalog.items.first?.diagnostic == .unsupported, "Unsupported preference must report unsupported diagnostic")
        }
    }

    static func testExecutorStaleState() async throws {
        let definition = try unwrap(MacSystemPreferencesCatalog.byID["macos.finder.show-path-bar"], "Missing Finder path definition")
        let client = FakeDefaultsClient(values: [definition.id: .missing])
        let temp = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temp) }

        let executor = SystemPreferencesExecutor(
            definitions: [definition.id: definition],
            client: client,
            recoveryStore: SystemPreferencesRecoveryStore(rootURL: temp),
            refresher: SystemPreferencesRefresher()
        )
        let plan = makePlan(definition: definition, expected: .bool(false), desired: .bool(true))
        let result = try await executor.execute(plan, previousRecovery: nil)

        try expect(result.items.first?.failureReason == .settingChanged,
                   "Executor must not overwrite a preference changed after scan")
    }

    static func testExecutorVerificationFailure() async throws {
        let definition = try unwrap(MacSystemPreferencesCatalog.byID["macos.finder.show-path-bar"], "Missing Finder path definition")
        let client = FakeDefaultsClient(values: [definition.id: .bool(false)], behavior: .ignoreWrites)
        let temp = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temp) }

        let executor = SystemPreferencesExecutor(
            definitions: [definition.id: definition],
            client: client,
            recoveryStore: SystemPreferencesRecoveryStore(rootURL: temp),
            refresher: SystemPreferencesRefresher()
        )
        let result = try await executor.execute(
            makePlan(definition: definition, expected: .bool(false), desired: .bool(true)),
            previousRecovery: nil
        )

        try expect(result.items.first?.failureReason == .verificationFailed,
                   "Executor must fail when read-back does not match the desired value")
    }

    static func testRecoveryRoundTrip() async throws {
        let definition = try unwrap(MacSystemPreferencesCatalog.byID["macos.dock.use-scale-effect"], "Missing Dock definition")
        let client = FakeDefaultsClient(values: [definition.id: .text("genie")])
        let temp = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temp) }

        let recoveryStore = SystemPreferencesRecoveryStore(rootURL: temp)
        let executor = SystemPreferencesExecutor(
            definitions: [definition.id: definition],
            client: client,
            recoveryStore: recoveryStore,
            refresher: SystemPreferencesRefresher()
        )

        let optimize = makePlan(
            definition: definition,
            expected: .text("genie"),
            desired: .text("scale")
        )
        let optimizedResult = try await executor.execute(optimize, previousRecovery: nil)
        try expect(optimizedResult.items.first?.verified == true, "Optimization should verify")

        let saved = await recoveryStore.load()
        try expect(saved?.items.first?.originalValue == .text("genie"), "Recovery must persist original value before mutation")
        try expect(saved?.items.first?.optimizedValue == .text("scale"), "Recovery must persist GatePass written value")

        let current = SystemPreferenceItem(
            definition: definition,
            currentValue: .text("scale"),
            status: .optimized,
            diagnostic: nil,
            restoreAvailable: true
        )
        let catalog = SystemPreferencesCatalog(
            scanID: UUID(),
            revision: "test",
            scannedAt: Date(),
            elapsed: 0,
            items: [current],
            recoveryAvailable: true
        )
        let recoveryPlan = SystemPreferencesPlanner().prepareRecovery(catalog: catalog, recovery: try unwrap(saved, "Recovery document missing"))
        let restored = try await executor.execute(recoveryPlan, previousRecovery: saved)

        try expect(restored.items.first?.verified == true, "Restore should verify")
        let restoredValue = try client.read(definition, timeout: 1)
        try expect(restoredValue == .text("genie"), "Restore must return the original value")
        let clearedRecovery = await recoveryStore.load()
        try expect(clearedRecovery == nil, "Successful restore must clear completed recovery entries")
    }

    static func testPartialFailure() async throws {
        let good = try unwrap(MacSystemPreferencesCatalog.byID["macos.dock.use-scale-effect"], "Missing good definition")
        let denied = try unwrap(MacSystemPreferencesCatalog.byID["macos.finder.show-path-bar"], "Missing denied definition")
        let client = FakeDefaultsClient(
            values: [good.id: .text("genie"), denied.id: .bool(false)],
            deniedIDs: [denied.id]
        )
        let temp = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temp) }

        let executor = SystemPreferencesExecutor(
            definitions: [good.id: good, denied.id: denied],
            client: client,
            recoveryStore: SystemPreferencesRecoveryStore(rootURL: temp),
            refresher: SystemPreferencesRefresher()
        )
        let now = Date()
        let plan = SystemPreferencesChangePlan(
            id: UUID(),
            scanID: UUID(),
            catalogRevision: "test",
            createdAt: now,
            expiresAt: now.addingTimeInterval(300),
            items: [
                .init(settingID: good.id, target: .optimized, expectedValue: .text("genie"), desiredValue: .text("scale"), requiresRestart: good.requiresRestart, riskLevel: good.riskLevel),
                .init(settingID: denied.id, target: .optimized, expectedValue: .bool(false), desiredValue: .bool(true), requiresRestart: denied.requiresRestart, riskLevel: denied.riskLevel)
            ],
            skippedItems: []
        )
        let result = try await executor.execute(plan, previousRecovery: nil)

        try expect(result.changedCount == 1, "One item should still succeed when another item fails")
        try expect(result.failedCount == 1, "Denied item should be reported as failed")
        try expect(result.items.first(where: { $0.settingID == denied.id })?.failureReason == .permissionDenied,
                   "Denied item must report permissionDenied")
    }

    static func testHistoryPersistence() async throws {
        let temp = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temp) }
        let store = SystemPreferencesHistoryStore(rootURL: temp)
        let result = SystemPreferencesChangeResult(
            id: UUID(),
            planID: UUID(),
            createdAt: Date(),
            items: [
                .init(settingID: "macos.finder.show-path-bar", outcome: .changed, verified: true, failureReason: nil)
            ]
        )
        try await store.append(result)
        let records = await store.load()

        try expect(records.count == 1, "History store should persist records")
        try expect(records.first?.id == result.id, "History store should preserve result IDs")
    }

    static func testRealDefaultsClientRoundTrip() throws {
        let domain = "com.ipotatow.GatePass.SystemPreferencesTests.\(UUID().uuidString)"
        let definition = SystemPreferenceDefinition(
            id: "test.defaults.bool",
            titleZH: "测试",
            titleEN: "Test",
            summaryZH: "",
            summaryEN: "",
            category: .productivity,
            selectionKind: .custom,
            riskLevel: .standard,
            domain: domain,
            key: "Enabled",
            valueType: .boolean,
            defaultValue: .missing,
            recommendedValue: .bool(true),
            disabledValue: nil,
            requiresRestart: false
        )
        let intDefinition = SystemPreferenceDefinition(
            id: "test.defaults.int", titleZH: "测试", titleEN: "Test", summaryZH: "", summaryEN: "",
            category: .productivity, selectionKind: .custom, riskLevel: .standard,
            domain: domain, key: "Count", valueType: .integer, defaultValue: .missing,
            recommendedValue: .int(7), disabledValue: nil, requiresRestart: false
        )
        let textDefinition = SystemPreferenceDefinition(
            id: "test.defaults.text", titleZH: "测试", titleEN: "Test", summaryZH: "", summaryEN: "",
            category: .productivity, selectionKind: .custom, riskLevel: .standard,
            domain: domain, key: "Name", valueType: .text, defaultValue: .missing,
            recommendedValue: .text("GatePass test"), disabledValue: nil, requiresRestart: false
        )
        let client = SystemDefaultsClient()
        defer { deleteDefaultsDomain(domain) }

        try client.write(.bool(true), definition: definition, timeout: 3)
        let boolValue = try client.read(definition, timeout: 3)
        try expect(boolValue == .bool(true), "Real defaults client should round-trip a boolean value")

        try client.write(.int(7), definition: intDefinition, timeout: 3)
        let intValue = try client.read(intDefinition, timeout: 3)
        try expect(intValue == .int(7), "Real defaults client should round-trip an integer value")

        try client.write(.text("GatePass test"), definition: textDefinition, timeout: 3)
        let textValue = try client.read(textDefinition, timeout: 3)
        try expect(textValue == .text("GatePass test"), "Real defaults client should round-trip a text value")

        try client.write(.missing, definition: definition, timeout: 3)
        let missingValue = try client.read(definition, timeout: 3)
        try expect(missingValue == .missing, "Real defaults client should delete a test key")
    }

    static func makePlan(
        definition: SystemPreferenceDefinition,
        expected: SystemPreferenceValue,
        desired: SystemPreferenceValue
    ) -> SystemPreferencesChangePlan {
        let now = Date()
        return SystemPreferencesChangePlan(
            id: UUID(),
            scanID: UUID(),
            catalogRevision: "test",
            createdAt: now,
            expiresAt: now.addingTimeInterval(300),
            items: [
                .init(
                    settingID: definition.id,
                    target: .optimized,
                    expectedValue: expected,
                    desiredValue: desired,
                    requiresRestart: definition.requiresRestart,
                    riskLevel: definition.riskLevel
                )
            ],
            skippedItems: []
        )
    }

    static func temporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("GatePassSystemPreferencesTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func deleteDefaultsDomain(_ domain: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["delete", domain]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }

    static func unwrap<T>(_ value: T?, _ message: String) throws -> T {
        guard let value else { throw TestFailure.failed(message) }
        return value
    }
}
