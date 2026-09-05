import AppKit
import Foundation

@main
enum GatePassUpdaterTests {
    static func main() async throws {
        try updateEndpointUsesBuiltInMirrors()
        try await processRunnerDrainsLargeOutput()
        try await installationScriptStagesBeforeReplacingAndKeepsRollback()
        try await installationScriptLeavesCurrentVersionOnVerificationFailure()
        try pendingInstallationConfirmationKeepsBackupOnMismatch()
        print("GatePass updater tests passed")
    }

    private static func updateEndpointUsesBuiltInMirrors() throws {
        let originalURL = URL(string: "https://api.github.com/repos/iPotatow/GatePass/releases")!

        let ghProxy = GatePassUpdateEndpoint.resolve(
            originalURL: originalURL,
            source: .ghProxy
        )
        try expect(
            ghProxy?.absoluteString == "https://gh-proxy.com/https://api.github.com/repos/iPotatow/GatePass/releases",
            "gh-proxy.com did not preserve the original URL"
        )

        let ghproxyNet = GatePassUpdateEndpoint.resolve(
            originalURL: originalURL,
            source: .ghproxyNet
        )
        try expect(
            ghproxyNet?.absoluteString == "https://ghproxy.net/https://api.github.com/repos/iPotatow/GatePass/releases",
            "ghproxy.net did not preserve the original URL"
        )

        let github = GatePassUpdateEndpoint.resolve(
            originalURL: originalURL,
            source: .github
        )
        try expect(github == originalURL, "GitHub source was unexpectedly rewritten")
    }

    private static func processRunnerDrainsLargeOutput() async throws {
        let output = try await GatePassUpdateProcessRunner.run(
            executable: "/bin/zsh",
            arguments: [
                "-c",
                "for i in {1..20000}; do print -r -- stdout-line; print -u2 -r -- stderr-line; done"
            ]
        )
        try expect(output.contains("stdout-line"), "Process output did not include stdout")
        try expect(output.contains("stderr-line"), "Process output did not include stderr")
        try expect(output.count > 300_000, "Process output was not fully drained")
    }

    private static func installationScriptStagesBeforeReplacingAndKeepsRollback() async throws {
        let fileManager = FileManager.default
        let root = try makeTemporaryRoot(named: "successful-install")
        defer { try? fileManager.removeItem(at: root) }

        let parent = root.appendingPathComponent("Applications with spaces", isDirectory: true)
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        let destination = parent.appendingPathComponent("Gate'Pass.app", isDirectory: true)
        try makeApp(at: destination, bundleIdentifier: "com.example.GatePass", version: "1.0.0", marker: "old")

        let staged = root.appendingPathComponent("staged/GatePass.app", isDirectory: true)
        try makeApp(at: staged, bundleIdentifier: "com.example.GatePass", version: "2.0.0", marker: "new")

        let updatesDirectory = root.appendingPathComponent("Updates", isDirectory: true)
        let updateRoot = updatesDirectory.appendingPathComponent("update-1", isDirectory: true)
        try fileManager.createDirectory(at: updateRoot, withIntermediateDirectories: true)
        let backupName = ".GatePass-backup-test"
        let script = GatePassUpdateInstaller.installScript(
            stagedApp: staged,
            destination: destination,
            updateRoot: updateRoot,
            backupName: backupName,
            expectedBundleIdentifier: "com.example.GatePass",
            expectedVersion: "2.0.0"
        )
        let scriptURL = updateRoot.appendingPathComponent("install-update.zsh")
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        _ = try? await GatePassUpdateProcessRunner.run(executable: "/bin/zsh", arguments: [scriptURL.path])

        let installedVersion = try readBundleVersion(at: destination)
        let installedMarker = try readMarker(at: destination)
        try expect(installedVersion == "2.0.0", "New app was not installed")
        try expect(installedMarker == "new", "Installed app was not copied completely")
        let backup = parent.appendingPathComponent(backupName, isDirectory: true)
        try expect(fileManager.fileExists(atPath: backup.path), "Rollback copy was removed before confirmation")
        let rollbackVersion = try readBundleVersion(at: backup)
        try expect(rollbackVersion == "1.0.0", "Rollback copy is not the old version")

        let record = GatePassUpdateInstaller.pendingInstallationRecord(
            destination: destination,
            backupName: backupName,
            bundleIdentifier: "com.example.GatePass",
            expectedVersion: "2.0.0"
        )
        try JSONEncoder().encode(record).write(
            to: updateRoot.appendingPathComponent("install-record.json"),
            options: .atomic
        )
        let cleanupError = GatePassUpdateInstaller.finalizePendingInstallation(
            in: updatesDirectory,
            installedAppURL: destination,
            installedBundleIdentifier: "com.example.GatePass",
            installedVersion: "2.0.0"
        )
        try expect(cleanupError == nil, "Confirmed update was not finalized: \(cleanupError ?? "unknown")")
        try expect(!fileManager.fileExists(atPath: backup.path), "Rollback copy was not cleaned after confirmation")
        try expect(!fileManager.fileExists(atPath: updateRoot.path), "Update staging directory was not cleaned after confirmation")
    }

    private static func installationScriptLeavesCurrentVersionOnVerificationFailure() async throws {
        let fileManager = FileManager.default
        let root = try makeTemporaryRoot(named: "failed-install")
        defer { try? fileManager.removeItem(at: root) }

        let parent = root.appendingPathComponent("Applications", isDirectory: true)
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        let destination = parent.appendingPathComponent("GatePass.app", isDirectory: true)
        try makeApp(at: destination, bundleIdentifier: "com.example.GatePass", version: "1.0.0", marker: "old")

        let staged = root.appendingPathComponent("staged/GatePass.app", isDirectory: true)
        try makeApp(at: staged, bundleIdentifier: "com.example.GatePass", version: "1.5.0", marker: "wrong-version")
        let updatesDirectory = root.appendingPathComponent("Updates", isDirectory: true)
        let updateRoot = updatesDirectory.appendingPathComponent("update-2", isDirectory: true)
        try fileManager.createDirectory(at: updateRoot, withIntermediateDirectories: true)
        let backupName = ".GatePass-backup-test"
        let scriptURL = updateRoot.appendingPathComponent("install-update.zsh")
        try GatePassUpdateInstaller.installScript(
            stagedApp: staged,
            destination: destination,
            updateRoot: updateRoot,
            backupName: backupName,
            expectedBundleIdentifier: "com.example.GatePass",
            expectedVersion: "2.0.0"
        ).write(to: scriptURL, atomically: true, encoding: .utf8)

        do {
            _ = try await GatePassUpdateProcessRunner.run(executable: "/bin/zsh", arguments: [scriptURL.path])
            throw TestFailure(message: "Invalid staged version unexpectedly installed")
        } catch is TestFailure {
            throw TestFailure(message: "Invalid staged version unexpectedly installed")
        } catch {
            // The installer exits non-zero, which is the expected failure.
        }

        let currentVersion = try readBundleVersion(at: destination)
        try expect(currentVersion == "1.0.0", "Failed verification changed the current app")
        try expect(!fileManager.fileExists(atPath: parent.appendingPathComponent(backupName).path), "Failed preflight created a rollback move")
        let message = GatePassUpdateInstaller.pendingFailureMessage(in: updatesDirectory)
        try expect(message?.contains("current version was not replaced") == true, "Failure state was not reported truthfully")
    }

    private static func pendingInstallationConfirmationKeepsBackupOnMismatch() throws {
        let fileManager = FileManager.default
        let root = try makeTemporaryRoot(named: "mismatched-confirmation")
        defer { try? fileManager.removeItem(at: root) }

        let destination = root.appendingPathComponent("GatePass.app", isDirectory: true)
        try makeApp(at: destination, bundleIdentifier: "com.example.GatePass", version: "3.0.0", marker: "new")
        let updatesDirectory = root.appendingPathComponent("Updates", isDirectory: true)
        let updateRoot = updatesDirectory.appendingPathComponent("update-3", isDirectory: true)
        try fileManager.createDirectory(at: updateRoot, withIntermediateDirectories: true)
        let backup = root.appendingPathComponent(".GatePass-backup-test", isDirectory: true)
        try makeApp(at: backup, bundleIdentifier: "com.example.GatePass", version: "2.0.0", marker: "old")
        let record = GatePassUpdateInstaller.pendingInstallationRecord(
            destination: destination,
            backupName: backup.lastPathComponent,
            bundleIdentifier: "com.example.GatePass",
            expectedVersion: "3.0.0"
        )
        try JSONEncoder().encode(record).write(to: updateRoot.appendingPathComponent("install-record.json"), options: .atomic)
        try "installed\n".write(to: updateRoot.appendingPathComponent("install-status"), atomically: true, encoding: .utf8)

        let message = GatePassUpdateInstaller.finalizePendingInstallation(
            in: updatesDirectory,
            installedAppURL: destination,
            installedBundleIdentifier: "com.example.GatePass",
            installedVersion: "4.0.0"
        )
        try expect(message?.contains("could not confirm") == true, "Mismatched installation was not reported")
        try expect(fileManager.fileExists(atPath: backup.path), "Rollback copy was removed after a mismatched confirmation")
        try expect(fileManager.fileExists(atPath: updateRoot.path), "Pending record was removed after a mismatched confirmation")
    }

    private static func makeTemporaryRoot(named name: String) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("gatepass-updater-\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private static func makeApp(at url: URL, bundleIdentifier: String, version: String, marker: String) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: url.appendingPathComponent("Contents", isDirectory: true), withIntermediateDirectories: true)
        let plist: [String: Any] = [
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundleShortVersionString": version,
            "CFBundlePackageType": "APPL"
        ]
        (plist as NSDictionary).write(to: url.appendingPathComponent("Contents/Info.plist"), atomically: true)
        try marker.write(to: url.appendingPathComponent("Contents/marker.txt"), atomically: true, encoding: .utf8)
    }

    private static func readBundleVersion(at url: URL) throws -> String {
        let plist = NSDictionary(contentsOf: url.appendingPathComponent("Contents/Info.plist")) as? [String: Any]
        guard let version = plist?["CFBundleShortVersionString"] as? String else {
            throw TestFailure(message: "Missing bundle version at \(url.path)")
        }
        return version
    }

    private static func readMarker(at url: URL) throws -> String {
        try String(contentsOf: url.appendingPathComponent("Contents/marker.txt"), encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw TestFailure(message: message) }
    }
}

private struct TestFailure: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}


enum GatePassLogCategory {
    static let updater = "Updater"
}

func printOS(_ items: Any..., separator: String = " ", category: String = GatePassLogCategory.updater) {
    _ = items
    _ = separator
    _ = category
}
