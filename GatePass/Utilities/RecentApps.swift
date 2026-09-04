//
//  RecentApps.swift
//  GatePass
//

import Foundation

struct RecentApp: Identifiable, Equatable {
    let url: URL
    let installedAt: Date

    var id: URL { url }
    var name: String { url.deletingPathExtension().lastPathComponent }
}

enum RecentAppsScanner {
    private static let applicationDirectories = [
        URL(fileURLWithPath: "/Applications", isDirectory: true),
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
    ]

    // macOS keeps the canonical copies of its built-in apps under this directory.
    // Candidate apps are still classified by bundle identifier, so a built-in app
    // located in /Applications is excluded as well.
    private static let macOSBuiltInBundleIdentifiers = bundleIdentifiers(
        in: URL(fileURLWithPath: "/System/Applications", isDirectory: true)
    )

    static func scanInstalledWithinLastWeek(now: Date = Date()) -> [RecentApp] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .creationDateKey]

        let apps = applicationDirectories.flatMap { directory in
            (try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )) ?? []
        }.compactMap { url -> RecentApp? in
            guard url.pathExtension.lowercased() == "app" else { return nil }
            let values = try? url.resourceValues(forKeys: keys)
            guard values?.isDirectory == true,
                  let creationDate = values?.creationDate,
                  creationDate >= cutoff,
                  !isMacOSBuiltInApplication(at: url) else { return nil }
            return RecentApp(url: url, installedAt: creationDate)
        }

        return Dictionary(grouping: apps, by: \.url)
            .compactMap { $0.value.first }
            .sorted { $0.installedAt > $1.installedAt }
    }

    private static func isMacOSBuiltInApplication(at url: URL) -> Bool {
        guard let bundleIdentifier = Bundle(url: url)?.bundleIdentifier else { return false }
        return macOSBuiltInBundleIdentifiers.contains(bundleIdentifier)
    }

    private static func bundleIdentifiers(in directory: URL) -> Set<String> {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var identifiers = Set<String>()
        for case let url as URL in enumerator {
            guard url.pathExtension.lowercased() == "app",
                  let bundleIdentifier = Bundle(url: url)?.bundleIdentifier else { continue }
            identifiers.insert(bundleIdentifier)
        }
        return identifiers
    }
}
