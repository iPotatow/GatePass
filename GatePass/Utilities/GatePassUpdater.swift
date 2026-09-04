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
        case .none:
            return nil
        case .daily:
            return 86_400
        case .weekly:
            return 604_800
        case .monthly:
            return 2_592_000
        }
    }
}

struct GatePassAsset: Codable {
    let name: String
    let url: String
    let browserDownloadURL: String

    enum CodingKeys: String, CodingKey {
        case name
        case url
        case browserDownloadURL = "browser_download_url"
    }
}

struct GatePassRelease: Codable, Identifiable {
    let id: Int
    let tagName: String
    let name: String
    let body: String
    let assets: [GatePassAsset]

    enum CodingKeys: String, CodingKey {
        case id
        case tagName = "tag_name"
        case name
        case body
        case assets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        tagName = try container.decode(String.self, forKey: .tagName)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? tagName
        body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        assets = try container.decodeIfPresent([GatePassAsset].self, forKey: .assets) ?? []
    }

    func modifiedBody(owner: String, repo: String) -> NSAttributedString? {
        let cleanedBody = body.replacingOccurrences(
            of: #"!\[.*?\]\((.*?)\)"#,
            with: "",
            options: .regularExpression
        )
        let result = NSMutableAttributedString()

        for rawLine in cleanedBody.components(separatedBy: .newlines) {
            guard !rawLine.isEmpty else { continue }

            let line = rawLine
                .replacingOccurrences(of: "- [x]", with: "•")
                .replacingOccurrences(of: "- [ ]", with: "•")

            if line.hasPrefix("#") {
                let text = line.replacingOccurrences(of: #"^#+\s*"#, with: "", options: .regularExpression)
                let header = NSMutableAttributedString(string: text)
                header.addAttribute(
                    .font,
                    value: NSFont.systemFont(ofSize: 17, weight: .bold),
                    range: NSRange(location: 0, length: header.length)
                )
                result.append(header)
            } else {
                let attributedLine = NSMutableAttributedString(string: line)
                let pattern = #"#(\d+)"#
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(line.startIndex..., in: line)
                    for match in regex.matches(in: line, options: [], range: range).reversed() {
                        guard let issueRange = Range(match.range(at: 1), in: line) else { continue }
                        let issue = String(line[issueRange])
                        let fullIssue = "#\(issue)"
                        let url = "https://github.com/\(owner)/\(repo)/issues/\(issue)"
                        let linkRange = (attributedLine.string as NSString).range(of: fullIssue)
                        guard linkRange.location != NSNotFound else { continue }
                        attributedLine.addAttribute(.link, value: url, range: linkRange)
                        attributedLine.addAttribute(
                            .underlineStyle,
                            value: NSUnderlineStyle.single.rawValue,
                            range: linkRange
                        )
                    }
                }
                result.append(attributedLine)
            }
            result.append(NSAttributedString(string: "\n"))
        }

        return result.length == 0 ? nil : result
    }
}

struct GatePassVersion: Comparable {
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

    static func < (lhs: GatePassVersion, rhs: GatePassVersion) -> Bool {
        lhs.components.lexicographicallyPrecedes(rhs.components)
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
    @Published var nextUpdateDate: Date {
        didSet {
            defaults.set(nextUpdateDate.timeIntervalSinceReferenceDate, forKey: Keys.nextCheckDate)
        }
    }
    @Published private(set) var isChecking = false
    @Published private(set) var isUpdating = false
    @Published private(set) var updateError: String?
    @Published private(set) var forceUpdateRequested = false

    let owner: String
    let repo: String

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let frequency = "gatepass.updater.frequency"
        static let nextCheckDate = "gatepass.updater.nextCheckDate"
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

    var hasNewerGatePassRelease: Bool {
        guard let installed = GatePassVersion(currentVersion) else { return false }
        return releases
            .compactMap { GatePassVersion($0.tagName) }
            .contains(where: { $0 > installed })
    }

    init(owner: String, repo: String) {
        self.owner = owner
        self.repo = repo
        self.updateFrequency = .daily
        self.nextUpdateDate = Date()
        migratePreferences()

        if let raw = defaults.string(forKey: Keys.frequency),
           let frequency = GatePassUpdateFrequency(rawValue: raw) {
            self.updateFrequency = frequency
        } else {
            self.updateFrequency = .daily
        }

        if let stored = defaults.object(forKey: Keys.nextCheckDate) as? NSNumber,
           stored.doubleValue != 0 {
            self.nextUpdateDate = Date(timeIntervalSinceReferenceDate: stored.doubleValue)
        } else {
            self.nextUpdateDate = Date()
        }

        Task { [weak self] in
            self?.checkAndUpdateIfNeeded()
        }
    }

    func checkForUpdates(sheet: Bool = false, force: Bool = false, forceUpdate: Bool = false) {
        guard !isChecking, !isUpdating else { return }
        updateError = nil
        forceUpdateRequested = forceUpdate
        isChecking = true

        Task { [weak self] in
            guard let self else { return }
            do {
                let fetched = try await fetchReleases()
                releases = fetched
                updateAvailable = hasNewerGatePassRelease
                if sheet {
                    self.sheet = true
                }
                if force || forceUpdate {
                    self.sheet = true
                }
                if !forceUpdate {
                    setNextUpdateDate()
                }
            } catch {
                updateError = error.localizedDescription
                if sheet {
                    self.sheet = true
                }
                printOS("Updater: \(error.localizedDescription)", category: GatePassLogCategory.updater)
            }
            isChecking = false
        }
    }

    func checkReleaseNotes() {
        guard !isChecking, !isUpdating else { return }
        isChecking = true
        Task { [weak self] in
            guard let self else { return }
            do {
                releases = try await fetchReleases()
                updateAvailable = hasNewerGatePassRelease
            } catch {
                printOS("Updater: release notes unavailable — \(error.localizedDescription)", category: GatePassLogCategory.updater)
            }
            isChecking = false
        }
    }

    func checkAndUpdateIfNeeded() {
        guard updateFrequency != .none else { return }
        if Date() >= nextUpdateDate {
            checkForUpdates()
        } else {
            checkReleaseNotes()
        }
    }

    func setNextUpdateDate() {
        guard let interval = updateFrequency.interval else {
            nextUpdateDate = .distantFuture
            return
        }

        let now = Date()
        nextUpdateDate = Calendar.current.date(byAdding: .second, value: Int(interval), to: now) ?? now
    }

    func downloadUpdate() {
        guard !isUpdating, let release = installableRelease else { return }
        isUpdating = true
        updateError = nil
        progressBar = ("Preparing update…", 0.05)

        Task { [weak self] in
            guard let self else { return }
            do {
                try await stageAndLaunchUpdate(release: release)
            } catch {
                isUpdating = false
                forceUpdateRequested = false
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
        guard let current = GatePassVersion(currentVersion) else { return releases.first }
        return releases.first(where: { release in
            guard let version = GatePassVersion(release.tagName) else { return false }
            return version >= current
        }) ?? releases.first
    }

    private func fetchReleases() async throws -> [GatePassRelease] {
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases") else {
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
        return Array(decoded.sorted { lhs, rhs in
            guard let left = GatePassVersion(lhs.tagName), let right = GatePassVersion(rhs.tagName) else {
                return lhs.tagName > rhs.tagName
            }
            return left > right
        }.prefix(3))
    }

    private func stageAndLaunchUpdate(release: GatePassRelease) async throws {
        guard let asset = selectUpdateAsset(from: release.assets) else {
            throw GatePassUpdateError.noDownload
        }
        guard let downloadURL = URL(string: asset.browserDownloadURL.isEmpty ? asset.url : asset.browserDownloadURL) else {
            throw GatePassUpdateError.invalidURL
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
        defer {
            if !installerLaunched {
                try? fileManager.removeItem(at: updateRoot)
            }
        }

        progressBar = ("Downloading update…", 0.2)
        var request = URLRequest(url: downloadURL)
        request.setValue("application/octet-stream", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw GatePassUpdateError.downloadFailed
        }

        let archiveURL = updateRoot.appendingPathComponent(asset.name)
        try data.write(to: archiveURL, options: .atomic)
        progressBar = ("Verifying update…", 0.35)
        try await verifyChecksum(archiveURL: archiveURL, asset: asset, release: release)

        let extractionURL = updateRoot.appendingPathComponent("extracted", isDirectory: true)
        try fileManager.createDirectory(at: extractionURL, withIntermediateDirectories: true)
        try runProcess("/usr/bin/ditto", arguments: ["-xk", archiveURL.path, extractionURL.path])

        let appURLs = (fileManager.enumerator(at: extractionURL, includingPropertiesForKeys: nil)?.compactMap { $0 as? URL } ?? [])
            .filter { $0.pathExtension == "app" }
        guard appURLs.count == 1 else { throw GatePassUpdateError.invalidArchive }
        let stagedApp = appURLs[0]
        guard let stagedBundle = Bundle(url: stagedApp),
              stagedBundle.bundleIdentifier == Bundle.main.bundleIdentifier,
              let stagedVersion = GatePassVersion(stagedBundle.version),
              let releaseVersion = GatePassVersion(release.tagName),
              stagedVersion == releaseVersion else {
            throw GatePassUpdateError.invalidArchive
        }
        try runProcess("/usr/bin/codesign", arguments: ["--verify", "--deep", "--strict", stagedApp.path])
        try runProcess("/usr/sbin/spctl", arguments: ["--assess", "--type", "execute", stagedApp.path])
        progressBar = ("Ready to install…", 0.65)

        try launchInstaller(stagedApp: stagedApp, updateRoot: updateRoot)
        installerLaunched = true
        progressBar = ("Restarting GatePass…", 1)
        isUpdating = false
        NSApp.terminate(nil)
    }

    private func verifyChecksum(archiveURL: URL, asset: GatePassAsset, release: GatePassRelease) async throws {
        guard let checksumAsset = release.assets.first(where: {
            let name = $0.name.lowercased()
            return name == "sha256sums" || name == "sha256sums.txt" || name.contains("checksums")
        }) else {
            throw GatePassUpdateError.missingChecksum
        }
        guard let url = URL(string: checksumAsset.browserDownloadURL.isEmpty ? checksumAsset.url : checksumAsset.browserDownloadURL) else {
            throw GatePassUpdateError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200,
              let text = String(data: data, encoding: .utf8) else {
            throw GatePassUpdateError.checksumUnavailable
        }

        let expected = text.split(whereSeparator: \.isNewline).compactMap { line -> String? in
            let fields = line.split(maxSplits: 1, whereSeparator: \.isWhitespace)
            guard fields.count == 2 else { return nil }
            let filename = fields[1].trimmingCharacters(in: CharacterSet(charactersIn: " *"))
            return filename == asset.name ? String(fields[0]).lowercased() : nil
        }.first
        guard let expected else { throw GatePassUpdateError.checksumMissingForAsset }

        let digest = SHA256.hash(data: try Data(contentsOf: archiveURL))
        let actual = digest.map { String(format: "%02x", $0) }.joined()
        guard actual == expected else { throw GatePassUpdateError.checksumMismatch }
    }

    private func selectUpdateAsset(from assets: [GatePassAsset]) -> GatePassAsset? {
        let arch = {
#if arch(arm64)
            return "arm"
#else
            return "intel"
#endif
        }()
        let zipAssets = assets.filter { $0.name.lowercased().hasSuffix(".zip") }
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "GatePass"
        return zipAssets.first(where: { $0.name == "\(appName)-\(arch).zip" })
            ?? zipAssets.first(where: { $0.name == "\(appName).zip" })
            ?? zipAssets.first
    }

    private func launchInstaller(stagedApp: URL, updateRoot: URL) throws {
        let destination = Bundle.main.bundleURL
        let scriptURL = updateRoot.appendingPathComponent("install-update.zsh")
        let backupName = ".GatePass-backup-\(UUID().uuidString)"
        let script = """
        #!/bin/zsh
        set -euo pipefail
        old=\(shellQuote(destination.path))
        new=\(shellQuote(stagedApp.path))
        root=\(shellQuote(updateRoot.path))
        backup="${old:h}/\(backupName)"
        for _ in {1..30}; do
            /usr/bin/pgrep -x GatePass >/dev/null 2>&1 || break
            /bin/sleep 1
        done
        /bin/mv "$old" "$backup"
        if ! /usr/bin/ditto "$new" "$old"; then
            /bin/mv "$backup" "$old"
            exit 1
        fi
        /bin/rm -rf "$backup" "$root"
        /usr/bin/open "$old"
        """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: scriptURL.path)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = [scriptURL.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
    }

    private func runProcess(_ executable: String, arguments: [String]) throws {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = output
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let data = output.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw GatePassUpdateError.processFailed(message ?? executable)
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

        defaults.set("1", forKey: Keys.migrated)
        defaults.removeObject(forKey: legacyFrequency)
        defaults.removeObject(forKey: legacyNextDate)
    }

    private func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
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
    case processFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The update URL is invalid."
        case .invalidResponse: return "GitHub returned an invalid response."
        case let .httpStatus(status): return "GitHub returned HTTP status \(status)."
        case .noDownload: return "No compatible GatePass download was found."
        case .downloadFailed: return "The update download failed."
        case .missingChecksum: return "This release has no SHA-256 checksum asset."
        case .checksumUnavailable: return "The release checksum could not be downloaded."
        case .checksumMissingForAsset: return "The release has no checksum for this download."
        case .checksumMismatch: return "The downloaded update failed its SHA-256 check."
        case .invalidArchive: return "The update archive does not contain exactly one GatePass app."
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
                if updater.isChecking {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let release = updater.releases.first {
                Text("Latest release: \(release.tagName)")
                    .font(.headline)

                if let notes = release.modifiedBody(owner: updater.owner, repo: updater.repo) {
                    ScrollView {
                        Text(AttributedString(notes))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 230)
                }
            } else if let error = updater.updateError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.secondary)
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
                Button("Update") {
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
