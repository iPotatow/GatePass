import AppKit
import Combine
import CryptoKit
import Foundation
import SwiftUI

enum GatePassUpdateFrequency: String, CaseIterable, Identifiable {
    case none = "Never"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"

    var id: String { rawValue }

    var interval: TimeInterval? {
        switch self {
        case .none: return nil
        case .daily: return 86_400
        case .weekly: return 604_800
        case .monthly: return 2_592_000
        }
    }
}

struct GatePassAsset: Codable, Equatable {
    let name: String
    let url: String
    let browserDownloadURL: String

    enum CodingKeys: String, CodingKey {
        case name
        case url
        case browserDownloadURL = "browser_download_url"
    }
}

struct GatePassRelease: Codable, Identifiable, Equatable {
    let id: Int
    let tagName: String
    let name: String
    let body: String
    let assets: [GatePassAsset]
    let draft: Bool
    let prerelease: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case tagName = "tag_name"
        case name
        case body
        case assets
        case draft
        case prerelease
    }

    init(
        id: Int,
        tagName: String,
        name: String? = nil,
        body: String = "",
        assets: [GatePassAsset] = [],
        draft: Bool = false,
        prerelease: Bool = false
    ) {
        self.id = id
        self.tagName = tagName
        self.name = name ?? tagName
        self.body = body
        self.assets = assets
        self.draft = draft
        self.prerelease = prerelease
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        tagName = try container.decode(String.self, forKey: .tagName)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? tagName
        body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        assets = try container.decodeIfPresent([GatePassAsset].self, forKey: .assets) ?? []
        draft = try container.decodeIfPresent(Bool.self, forKey: .draft) ?? false
        prerelease = try container.decodeIfPresent(Bool.self, forKey: .prerelease) ?? false
    }

    var releaseNotes: AttributedString? {
        let cleaned = Self.cleanedReleaseBody(body)
        guard !cleaned.isEmpty else { return nil }

        if let markdown = try? AttributedString(
            markdown: cleaned,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        ) {
            return markdown
        }
        return AttributedString(cleaned)
    }

    static func stableSorted(_ releases: [GatePassRelease]) -> [GatePassRelease] {
        releases
            .filter { !$0.draft && !$0.prerelease && GatePassVersion($0.tagName) != nil }
            .sorted { lhs, rhs in
                guard let left = GatePassVersion(lhs.tagName), let right = GatePassVersion(rhs.tagName) else {
                    return lhs.tagName > rhs.tagName
                }
                return left > right
            }
    }

    static func cleanedReleaseBody(_ body: String) -> String {
        let withoutImages = body.replacingOccurrences(
            of: #"!\[.*?\]\((.*?)\)"#,
            with: "",
            options: .regularExpression
        )

        var seenNonEmptyLines = Set<String>()
        var result: [String] = []
        var previousWasBlank = false

        for rawLine in withoutImages.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                if !result.isEmpty && !previousWasBlank {
                    result.append("")
                }
                previousWasBlank = true
                continue
            }

            previousWasBlank = false
            if seenNonEmptyLines.insert(line).inserted {
                result.append(line)
            }
        }

        while result.last?.isEmpty == true { result.removeLast() }
        return result.joined(separator: "\n")
    }
}

struct GatePassVersion: Comparable, Equatable {
    let components: [Int]

    init?(_ rawValue: String) {
        let normalized = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .drop(while: { $0 == "v" || $0 == "V" })
        let core = normalized.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true).first ?? ""
        let parts = core.split(separator: ".", omittingEmptySubsequences: true)
        guard !parts.isEmpty, parts.allSatisfy({ Int($0) != nil }) else { return nil }
        components = parts.map { Int($0)! } + Array(repeating: 0, count: max(0, 3 - parts.count))
    }

    static func == (lhs: GatePassVersion, rhs: GatePassVersion) -> Bool {
        !(lhs < rhs) && !(rhs < lhs)
    }

    static func < (lhs: GatePassVersion, rhs: GatePassVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right }
        }
        return false
    }
}

enum GatePassUpdateSource: String, CaseIterable, Identifiable {
    case github
    case ghProxy = "gh-proxy.com"
    case ghproxyNet = "ghproxy.net"
    case legacyMirror = "mirror"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .github: return "GitHub"
        case .ghProxy, .legacyMirror: return "gh-proxy.com"
        case .ghproxyNet: return "ghproxy.net"
        }
    }

    var proxyPrefix: String? {
        switch self {
        case .github: return nil
        case .ghProxy: return "https://gh-proxy.com/"
        case .ghproxyNet: return "https://ghproxy.net/"
        case .legacyMirror: return "https://gh-proxy.com/"
        }
    }
}

struct GatePassUpdateEndpoint {
    static func resolve(originalURL: URL, source: GatePassUpdateSource) -> URL? {
        guard let proxyPrefix = source.proxyPrefix else { return originalURL }
        let resolvedString = "\(proxyPrefix)\(originalURL.absoluteString)"
        guard let resolvedURL = URL(string: resolvedString),
              resolvedURL.scheme?.lowercased() == "https",
              resolvedURL.host != nil else {
            return nil
        }
        return resolvedURL
    }
}

struct GatePassUpdateAssetSelector {
    static func select(
        from assets: [GatePassAsset],
        appName: String,
        architecture: String
    ) -> GatePassAsset? {
        let zipAssets = assets.filter { $0.name.lowercased().hasSuffix(".zip") }
        return zipAssets.first(where: { $0.name == "\(appName)-\(architecture).zip" })
            ?? zipAssets.first(where: { $0.name == "\(appName).zip" })
            ?? zipAssets.first
    }
}

struct GatePassChecksumManifest {
    static func expectedSHA256(in text: String, for assetName: String) -> String? {
        text.split(whereSeparator: \.isNewline).compactMap { line -> String? in
            let fields = line.split(maxSplits: 1, whereSeparator: \.isWhitespace)
            guard fields.count == 2 else { return nil }
            let filename = fields[1].trimmingCharacters(in: CharacterSet(charactersIn: " *"))
            guard filename == assetName else { return nil }
            let hash = String(fields[0]).lowercased()
            guard hash.count == 64, hash.allSatisfy({ $0.isHexDigit }) else { return nil }
            return hash
        }.first
    }
}

enum GatePassUpdateCheckReason: Equatable {
    case background
    case manual
    case reinstallCurrent
}

enum GatePassUpdatePhase: Equatable {
    case idle
    case checking
    case upToDate
    case updateAvailable
    case downloading
    case verifying
    case installing
    case restarting
    case failed
}

struct GatePassPendingInstallation: Codable {
    let destinationPath: String
    let backupPath: String
    let bundleIdentifier: String
    let expectedVersion: String
}

struct GatePassUpdateInstaller {
    private static let statusFileName = "install-status"
    private static let recordFileName = "install-record.json"

    static func installScript(
        stagedApp: URL,
        destination: URL,
        updateRoot: URL,
        backupName: String,
        expectedBundleIdentifier: String,
        expectedVersion: String,
        parentProcessID: Int32? = nil
    ) -> String {
        let backup = destination.deletingLastPathComponent().appendingPathComponent(backupName)
        let candidate = destination.deletingLastPathComponent()
            .appendingPathComponent(".GatePass-install-\(UUID().uuidString)", isDirectory: true)
        let status = updateRoot.appendingPathComponent(statusFileName)

        let waitForParent = parentProcessID.map { """
        parent_pid=\($0)
        while /bin/kill -0 "$parent_pid" >/dev/null 2>&1; do
            /bin/sleep 1
        done
        """ } ?? ""

        return """
        #!/bin/zsh
        set -u
        old=\(shellQuote(destination.path))
        new=\(shellQuote(stagedApp.path))
        backup=\(shellQuote(backup.path))
        candidate=\(shellQuote(candidate.path))
        status_path=\(shellQuote(status.path))
        expected_id=\(shellQuote(expectedBundleIdentifier))
        expected_version=\(shellQuote(expectedVersion))

        write_status() {
            /usr/bin/printf '%s\\n' "$1" > "$status_path" 2>/dev/null || true
        }

        remove_candidate() {
            if [[ -e "$candidate" ]]; then
                /bin/rm -rf "$candidate" >/dev/null 2>&1 || true
            fi
        }

        verify_bundle() {
            local bundle="$1"
            [[ -d "$bundle" ]] || return 1
            local actual_id actual_version
            actual_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$bundle/Contents/Info.plist" 2>/dev/null) || return 1
            actual_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$bundle/Contents/Info.plist" 2>/dev/null) || return 1
            [[ "$actual_id" == "$expected_id" && "$actual_version" == "$expected_version" ]]
        }

        restore_backup() {
            if [[ -e "$old" ]]; then
                /bin/rm -rf "$old" >/dev/null 2>&1 || return 1
            fi
            /bin/mv "$backup" "$old" >/dev/null 2>&1 || return 1
            verify_bundle "$old"
        }

        \(waitForParent)

        if ! /usr/bin/ditto "$new" "$candidate" >/dev/null 2>&1; then
            remove_candidate
            write_status "failed_preflight"
            exit 1
        fi
        if ! verify_bundle "$candidate"; then
            remove_candidate
            write_status "failed_preflight"
            exit 1
        fi

        if ! /bin/mv "$old" "$backup" >/dev/null 2>&1; then
            remove_candidate
            write_status "failed_swap"
            exit 1
        fi

        if ! /bin/mv "$candidate" "$old" >/dev/null 2>&1; then
            if restore_backup; then
                write_status "failed_swap_restored"
            else
                write_status "failed_restore"
            fi
            remove_candidate
            exit 1
        fi

        if ! verify_bundle "$old"; then
            if restore_backup; then
                write_status "failed_post_install_restored"
            else
                write_status "failed_restore"
            fi
            exit 1
        fi

        write_status "installed"
        /usr/bin/open "$old" >/dev/null 2>&1 || write_status "installed_open_failed"
        exit 0
        """
    }

    static func pendingInstallationRecord(
        destination: URL,
        backupName: String,
        bundleIdentifier: String,
        expectedVersion: String
    ) -> GatePassPendingInstallation {
        GatePassPendingInstallation(
            destinationPath: destination.path,
            backupPath: destination.deletingLastPathComponent().appendingPathComponent(backupName).path,
            bundleIdentifier: bundleIdentifier,
            expectedVersion: expectedVersion
        )
    }

    static func finalizePendingInstallation(
        in updatesDirectory: URL,
        installedAppURL: URL,
        installedBundleIdentifier: String?,
        installedVersion: String,
        fileManager: FileManager = .default
    ) -> String? {
        guard let roots = try? fileManager.contentsOfDirectory(
            at: updatesDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        for root in roots {
            let statusURL = root.appendingPathComponent(statusFileName)
            guard let status = try? String(contentsOf: statusURL, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  status == "installed" || status == "installed_open_failed" else {
                continue
            }
            let recordURL = root.appendingPathComponent(recordFileName)
            guard let data = try? Data(contentsOf: recordURL),
                  let record = try? JSONDecoder().decode(GatePassPendingInstallation.self, from: data) else {
                return "GatePass installed an update, but its rollback record could not be read. The previous version was kept."
            }
            guard record.destinationPath == installedAppURL.path,
                  record.bundleIdentifier == installedBundleIdentifier,
                  record.expectedVersion == installedVersion else {
                return "GatePass installed an update, but could not confirm the installed version. The previous version was kept."
            }

            do {
                if fileManager.fileExists(atPath: record.backupPath) {
                    try fileManager.removeItem(atPath: record.backupPath)
                }
                try fileManager.removeItem(at: root)
            } catch {
                return "GatePass updated successfully, but could not remove the rollback copy. It was kept for recovery."
            }
        }
        return nil
    }

    static func pendingFailureMessage(
        in updatesDirectory: URL,
        fileManager: FileManager = .default
    ) -> String? {
        guard let roots = try? fileManager.contentsOfDirectory(
            at: updatesDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        for root in roots {
            let statusURL = root.appendingPathComponent(statusFileName)
            guard let status = try? String(contentsOf: statusURL, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  status.hasPrefix("failed_") else { continue }

            let message: String
            switch status {
            case "failed_restore":
                message = "The update failed and GatePass could not restore the previous version. A rollback copy was kept for recovery."
            case "failed_swap_restored", "failed_post_install_restored":
                message = "The update failed, so GatePass restored the previous version."
            default:
                message = "The update failed before installation completed. Your current version was not replaced."
            }
            if status != "failed_restore" {
                try? fileManager.removeItem(at: root)
            }
            return message
        }
        return nil
    }

    private static func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}

private final class GatePassUpdateProcessOutput: @unchecked Sendable {
    private let lock = NSLock()
    private var value = Data()

    func set(_ data: Data) {
        lock.lock()
        value = data
        lock.unlock()
    }

    func get() -> Data {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

struct GatePassUpdateProcessRunner {
    static func run(executable: String, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    continuation.resume(returning: try runSynchronously(executable: executable, arguments: arguments))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func runSynchronously(executable: String, arguments: [String]) throws -> String {
        let process = Process()
        let outputPipe = Pipe()
        let output = GatePassUpdateProcessOutput()
        let readGroup = DispatchGroup()

        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        try process.run()

        readGroup.enter()
        DispatchQueue.global(qos: .utility).async {
            output.set(outputPipe.fileHandleForReading.readDataToEndOfFile())
            readGroup.leave()
        }

        process.waitUntilExit()
        readGroup.wait()

        let text = String(data: output.get(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard process.terminationStatus == 0 else {
            throw GatePassUpdateError.processFailed(text.isEmpty ? executable : text)
        }
        return text
    }
}

@MainActor
final class GatePassUpdater: ObservableObject {
    @Published var updateAvailable = false
    @Published var sheet = false
    @Published var releases: [GatePassRelease] = []
    @Published var progressBar: (String, Double) = ("", 0)
    @Published var updateFrequency: GatePassUpdateFrequency {
        didSet {
            defaults.set(updateFrequency.rawValue, forKey: Keys.frequency)
            setNextUpdateDate()
        }
    }
    @Published var updateSource: GatePassUpdateSource {
        didSet { defaults.set(updateSource.rawValue, forKey: Keys.updateSource) }
    }
    @Published var nextUpdateDate: Date {
        didSet { defaults.set(nextUpdateDate.timeIntervalSinceReferenceDate, forKey: Keys.nextCheckDate) }
    }
    @Published private(set) var isChecking = false
    @Published private(set) var isUpdating = false
    @Published private(set) var updateError: String?
    @Published private(set) var forceUpdateRequested = false
    @Published private(set) var phase: GatePassUpdatePhase = .idle

    let owner: String
    let repo: String

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let frequency = "gatepass.updater.frequency"
        static let nextCheckDate = "gatepass.updater.nextCheckDate"
        static let updateSource = "gatepass.updater.updateSource"
        static let migrated = "gatepass.updater.preferencesMigratedVersion"
    }

    private var legacyKeyPrefix: String { ["alin", "foundation"].joined() }

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    var displayVersion: String {
        let normalized = currentVersion
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .drop(while: { $0 == "v" || $0 == "V" })
        return "v\(normalized)"
    }

    var hasNewerGatePassRelease: Bool { latestNewerRelease != nil }

    private var latestNewerRelease: GatePassRelease? {
        guard let installed = GatePassVersion(currentVersion) else { return nil }
        return releases.first { release in
            guard let version = GatePassVersion(release.tagName), version > installed else { return false }
            return selectUpdateAsset(from: release.assets) != nil && checksumAsset(in: release) != nil
        }
    }

    init(owner: String, repo: String) {
        self.owner = owner
        self.repo = repo
        self.updateFrequency = .daily
        self.updateSource = .github
        self.nextUpdateDate = Date()
        migratePreferences()

        if let raw = defaults.string(forKey: Keys.frequency),
           let frequency = GatePassUpdateFrequency(rawValue: raw) {
            self.updateFrequency = frequency
        } else {
            self.updateFrequency = .daily
        }

        if let raw = defaults.string(forKey: Keys.updateSource),
           let source = GatePassUpdateSource(rawValue: raw) {
            if source == .legacyMirror {
                let legacyMirrorURL = defaults.string(forKey: "gatepass.updater.mirrorURL")?.lowercased() ?? ""
                self.updateSource = legacyMirrorURL.localizedStandardContains("ghproxy.net") ? .ghproxyNet : .ghProxy
                defaults.set(self.updateSource.rawValue, forKey: Keys.updateSource)
            } else {
                self.updateSource = source
            }
        } else {
            self.updateSource = .github
        }
        defaults.removeObject(forKey: "gatepass.updater.mirrorURL")

        if let stored = defaults.object(forKey: Keys.nextCheckDate) as? NSNumber,
           stored.doubleValue != 0 {
            self.nextUpdateDate = Date(timeIntervalSinceReferenceDate: stored.doubleValue)
        } else {
            self.nextUpdateDate = Date()
        }

        recordPendingInstallationState()
        Task { [weak self] in self?.checkAndUpdateIfNeeded() }
    }

    func checkForUpdates(reason: GatePassUpdateCheckReason) {
        guard !isChecking, !isUpdating else { return }
        isChecking = true
        phase = .checking
        updateError = nil
        forceUpdateRequested = reason == .reinstallCurrent

        Task { [weak self] in
            guard let self else { return }
            do {
                releases = try await fetchReleases()
                updateAvailable = hasNewerGatePassRelease

                switch reason {
                case .background:
                    phase = updateAvailable ? .updateAvailable : .idle
                case .manual:
                    phase = updateAvailable ? .updateAvailable : .upToDate
                    sheet = true
                case .reinstallCurrent:
                    phase = updateAvailable ? .updateAvailable : .upToDate
                    sheet = true
                }

                if reason != .reinstallCurrent { setNextUpdateDate() }
            } catch {
                updateError = error.localizedDescription
                phase = .failed
                if reason != .background { sheet = true }
                printOS("Updater: \(error.localizedDescription)", category: GatePassLogCategory.updater)
            }
            isChecking = false
        }
    }

    func checkForUpdates(sheet: Bool = false, force: Bool = false, forceUpdate: Bool = false) {
        let reason: GatePassUpdateCheckReason
        if forceUpdate {
            reason = .reinstallCurrent
        } else if sheet || force {
            reason = .manual
        } else {
            reason = .background
        }
        checkForUpdates(reason: reason)
    }

    func checkReleaseNotes() {
        guard !isChecking, !isUpdating else { return }
        isChecking = true
        Task { [weak self] in
            guard let self else { return }
            do {
                releases = try await fetchReleases()
                updateAvailable = hasNewerGatePassRelease
                updateError = nil
                phase = updateAvailable ? .updateAvailable : .idle
            } catch {
                printOS("Updater: release notes unavailable — \(error.localizedDescription)", category: GatePassLogCategory.updater)
            }
            isChecking = false
        }
    }

    func checkAndUpdateIfNeeded() {
        guard updateFrequency != .none else { return }
        if Date() >= nextUpdateDate {
            checkForUpdates(reason: .background)
        } else {
            checkReleaseNotes()
        }
    }

    func setNextUpdateDate() {
        guard let interval = updateFrequency.interval else {
            nextUpdateDate = .distantFuture
            return
        }
        nextUpdateDate = Date().addingTimeInterval(interval)
    }

    func downloadUpdate() {
        guard !isUpdating, let release = installableRelease else { return }
        isUpdating = true
        updateError = nil
        phase = .downloading
        progressBar = ("Downloading update…", 0.10)

        Task { [weak self] in
            guard let self else { return }
            do {
                try await stageAndLaunchUpdate(release: release)
            } catch {
                isUpdating = false
                phase = .failed
                updateError = error.localizedDescription
                progressBar = ("Update failed", 0)
                printOS("Updater: \(error.localizedDescription)", category: GatePassLogCategory.updater)
            }
        }
    }

    @ViewBuilder
    func getUpdateView() -> some View {
        GatePassUpdateView(updater: self)
    }

    private var installableRelease: GatePassRelease? {
        if forceUpdateRequested,
           let current = GatePassVersion(currentVersion),
           let exact = releases.first(where: { GatePassVersion($0.tagName) == current }),
           selectUpdateAsset(from: exact.assets) != nil,
           checksumAsset(in: exact) != nil {
            return exact
        }
        return latestNewerRelease
    }

    private func fetchReleases() async throws -> [GatePassRelease] {
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases?per_page=30") else {
            throw GatePassUpdateError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("GatePass/\(currentVersion)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GatePassUpdateError.invalidResponse }
        guard http.statusCode == 200 else { throw GatePassUpdateError.httpStatus(http.statusCode) }

        let decoded = try JSONDecoder().decode([GatePassRelease].self, from: data)
        return Array(GatePassRelease.stableSorted(decoded).prefix(10))
    }

    private func stageAndLaunchUpdate(release: GatePassRelease) async throws {
        guard let asset = selectUpdateAsset(from: release.assets) else { throw GatePassUpdateError.noDownload }
        guard let originalDownloadURL = assetDownloadURL(asset) else { throw GatePassUpdateError.invalidURL }

        let destination = Bundle.main.bundleURL
        let parent = destination.deletingLastPathComponent()
        guard FileManager.default.isWritableFile(atPath: parent.path) else {
            throw GatePassUpdateError.installLocationNotWritable(parent.path)
        }

        let fileManager = FileManager.default
        let support = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let updateRoot = support.appendingPathComponent("GatePass", isDirectory: true)
            .appendingPathComponent("Updates", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: updateRoot, withIntermediateDirectories: true)
        var installerLaunched = false
        defer { if !installerLaunched { try? fileManager.removeItem(at: updateRoot) } }

        progressBar = ("Downloading update…", 0.20)
        phase = .downloading
        let archiveData = try await downloadAssetData(originalURL: originalDownloadURL, accept: "application/octet-stream")
        let archiveURL = updateRoot.appendingPathComponent(asset.name)
        try archiveData.write(to: archiveURL, options: .atomic)

        progressBar = ("Verifying update…", 0.40)
        phase = .verifying
        try await verifyChecksum(archiveURL: archiveURL, asset: asset, release: release)

        let extractionURL = updateRoot.appendingPathComponent("extracted", isDirectory: true)
        try fileManager.createDirectory(at: extractionURL, withIntermediateDirectories: true)
        _ = try await GatePassUpdateProcessRunner.run(
            executable: "/usr/bin/ditto",
            arguments: ["-xk", archiveURL.path, extractionURL.path]
        )

        let appURLs = try fileManager.contentsOfDirectory(
            at: extractionURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ).filter { $0.pathExtension.lowercased() == "app" }
        guard appURLs.count == 1 else { throw GatePassUpdateError.invalidArchive }

        let stagedApp = appURLs[0]
        guard let currentBundleIdentifier = Bundle.main.bundleIdentifier,
              let stagedBundle = Bundle(url: stagedApp),
              stagedBundle.bundleIdentifier == currentBundleIdentifier,
              let stagedShortVersion = stagedBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              let stagedVersion = GatePassVersion(stagedShortVersion),
              let releaseVersion = GatePassVersion(release.tagName),
              stagedVersion == releaseVersion else {
            throw GatePassUpdateError.invalidArchive
        }

        progressBar = ("Installing update…", 0.70)
        phase = .installing
        try launchInstaller(
            stagedApp: stagedApp,
            updateRoot: updateRoot,
            expectedBundleIdentifier: currentBundleIdentifier,
            expectedVersion: stagedShortVersion
        )
        installerLaunched = true
        progressBar = ("Restarting GatePass…", 1)
        phase = .restarting
        isUpdating = false
        NSApp.terminate(nil)
    }

    private func verifyChecksum(archiveURL: URL, asset: GatePassAsset, release: GatePassRelease) async throws {
        guard let checksumAsset = checksumAsset(in: release),
              let originalURL = assetDownloadURL(checksumAsset) else {
            throw GatePassUpdateError.missingChecksum
        }

        let data = try await downloadAssetData(originalURL: originalURL, accept: "text/plain, application/octet-stream")
        guard let text = String(data: data, encoding: .utf8) else { throw GatePassUpdateError.checksumUnavailable }
        guard let expected = GatePassChecksumManifest.expectedSHA256(in: text, for: asset.name) else {
            throw GatePassUpdateError.checksumMissingForAsset
        }

        let digest = SHA256.hash(data: try Data(contentsOf: archiveURL))
        let actual = digest.map { String(format: "%02x", $0) }.joined()
        guard actual == expected else { throw GatePassUpdateError.checksumMismatch }
    }

    private func downloadAssetData(originalURL: URL, accept: String) async throws -> Data {
        let candidateURLs: [URL]
        if updateSource == .github {
            candidateURLs = [originalURL]
        } else if let mirrored = GatePassUpdateEndpoint.resolve(originalURL: originalURL, source: updateSource) {
            candidateURLs = [mirrored, originalURL]
        } else {
            candidateURLs = [originalURL]
        }

        var lastStatus: Int?
        var lastError: Error?

        for (index, url) in candidateURLs.enumerated() {
            do {
                var request = URLRequest(url: url)
                request.setValue(accept, forHTTPHeaderField: "Accept")
                request.setValue("GatePass/\(currentVersion)", forHTTPHeaderField: "User-Agent")
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else { throw GatePassUpdateError.invalidResponse }
                guard http.statusCode == 200 else {
                    lastStatus = http.statusCode
                    if index + 1 < candidateURLs.count { continue }
                    throw GatePassUpdateError.httpStatus(http.statusCode)
                }
                return data
            } catch {
                lastError = error
                if index + 1 < candidateURLs.count {
                    printOS(
                        "Updater: \(updateSource.displayName) download failed, retrying via GitHub — \(error.localizedDescription)",
                        category: GatePassLogCategory.updater
                    )
                    continue
                }
            }
        }

        if let lastStatus { throw GatePassUpdateError.httpStatus(lastStatus) }
        if let lastError { throw lastError }
        throw GatePassUpdateError.downloadFailed
    }

    private func selectUpdateAsset(from assets: [GatePassAsset]) -> GatePassAsset? {
#if arch(arm64)
        let architecture = "arm"
#else
        let architecture = "intel"
#endif
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "GatePass"
        return GatePassUpdateAssetSelector.select(from: assets, appName: appName, architecture: architecture)
    }

    private func checksumAsset(in release: GatePassRelease) -> GatePassAsset? {
        release.assets.first { asset in
            let name = asset.name.lowercased()
            return name == "sha256sums" || name == "sha256sums.txt" || name.contains("checksums")
        }
    }

    private func assetDownloadURL(_ asset: GatePassAsset) -> URL? {
        URL(string: asset.browserDownloadURL.isEmpty ? asset.url : asset.browserDownloadURL)
    }

    private func launchInstaller(
        stagedApp: URL,
        updateRoot: URL,
        expectedBundleIdentifier: String,
        expectedVersion: String
    ) throws {
        let destination = Bundle.main.bundleURL
        let backupName = ".GatePass-backup-\(UUID().uuidString)"
        let record = GatePassUpdateInstaller.pendingInstallationRecord(
            destination: destination,
            backupName: backupName,
            bundleIdentifier: expectedBundleIdentifier,
            expectedVersion: expectedVersion
        )
        let recordURL = updateRoot.appendingPathComponent("install-record.json")
        try JSONEncoder().encode(record).write(to: recordURL, options: .atomic)

        let scriptURL = updateRoot.appendingPathComponent("install-update.zsh")
        let script = GatePassUpdateInstaller.installScript(
            stagedApp: stagedApp,
            destination: destination,
            updateRoot: updateRoot,
            backupName: backupName,
            expectedBundleIdentifier: expectedBundleIdentifier,
            expectedVersion: expectedVersion,
            parentProcessID: ProcessInfo.processInfo.processIdentifier
        )
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: scriptURL.path)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [scriptURL.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
    }

    private func recordPendingInstallationState() {
        let fileManager = FileManager.default
        guard let support = try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ) else { return }
        let updatesDirectory = support.appendingPathComponent("GatePass/Updates", isDirectory: true)
        if let message = GatePassUpdateInstaller.finalizePendingInstallation(
            in: updatesDirectory,
            installedAppURL: Bundle.main.bundleURL,
            installedBundleIdentifier: Bundle.main.bundleIdentifier,
            installedVersion: currentVersion,
            fileManager: fileManager
        ) {
            updateError = message
            phase = .failed
        } else if let message = GatePassUpdateInstaller.pendingFailureMessage(
            in: updatesDirectory,
            fileManager: fileManager
        ) {
            updateError = message
            phase = .failed
        }
    }

    private func migratePreferences() {
        let legacyFrequency = "\(legacyKeyPrefix).updater.updateFrequency"
        let legacyNextDate = "\(legacyKeyPrefix).updater.nextUpdateDate"

        if defaults.object(forKey: Keys.frequency) == nil,
           let value = defaults.string(forKey: legacyFrequency) {
            defaults.set(value, forKey: Keys.frequency)
        }
        if defaults.object(forKey: Keys.nextCheckDate) == nil,
           let value = defaults.object(forKey: legacyNextDate) as? NSNumber,
           value.doubleValue != 0 {
            defaults.set(value.doubleValue, forKey: Keys.nextCheckDate)
        }

        defaults.set("2", forKey: Keys.migrated)
        defaults.removeObject(forKey: legacyFrequency)
        defaults.removeObject(forKey: legacyNextDate)
    }
}

private enum GatePassUpdateError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case noDownload
    case downloadFailed
    case missingChecksum
    case checksumUnavailable
    case checksumMissingForAsset
    case checksumMismatch
    case invalidArchive
    case installLocationNotWritable(String)
    case processFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The update URL is invalid."
        case .invalidResponse: return "The update source returned an invalid response."
        case let .httpStatus(status): return "The update source returned HTTP status \(status)."
        case .noDownload: return "No compatible GatePass download was found."
        case .downloadFailed: return "The update download failed."
        case .missingChecksum: return "This release has no SHA-256 checksum asset."
        case .checksumUnavailable: return "The release checksum could not be downloaded."
        case .checksumMissingForAsset: return "The release has no checksum for this download."
        case .checksumMismatch: return "The downloaded update failed its SHA-256 check."
        case .invalidArchive: return "The update archive does not contain exactly one valid GatePass app."
        case let .installLocationNotWritable(path):
            return "GatePass cannot replace the app in \(path). Move it to a folder you can write to, then try again."
        case let .processFailed(command): return "The update verification command failed: \(command)"
        }
    }
}

struct GatePassUpdateView: View {
    @ObservedObject var updater: GatePassUpdater
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GatePass Updates")
                        .font(.title2.weight(.semibold))
                    Text("Installed: \(updater.displayVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if updater.isChecking { ProgressView().controlSize(.small) }
            }

            if let error = updater.updateError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
            } else if let release = updater.releases.first {
                Text("Latest release: \(release.tagName)")
                    .font(.headline)

                if let notes = release.releaseNotes {
                    ScrollView {
                        Text(notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 230)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "shippingbox")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("No release information")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if updater.isUpdating {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: updater.progressBar.1)
                    Text(updater.progressBar.0)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Button("Close") { dismiss() }
                Spacer()
                Button(updater.forceUpdateRequested ? "Reinstall" : "Update") {
                    updater.downloadUpdate()
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    (!updater.hasNewerGatePassRelease && !updater.forceUpdateRequested)
                        || updater.isUpdating
                        || updater.isChecking
                )
            }
        }
        .padding(24)
        .frame(width: 560, height: 420)
    }
}
