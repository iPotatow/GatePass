import Foundation

enum AppLanguage: String {
    case system
    case zhHans
    case english
}

func gatePassCopy(_ zhHans: String, _ english: String, language: AppLanguage) -> String {
    language == .english ? english : zhHans
}

@main
struct SystemPreferencesDefaultsAudit {
    enum AuditStatus: String {
        case pass = "PASS"
        case unsupported = "UNSUPPORTED"
        case restricted = "RESTRICTED"
        case writeFailed = "WRITE_FAILED"
        case readBackMismatch = "READBACK_MISMATCH"
        case restoreFailed = "RESTORE_FAILED"
        case readFailed = "READ_FAILED"
    }

    static func main() {
        let client = SystemDefaultsClient()
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let os = "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        var counts: [AuditStatus: Int] = [:]

        print("DEFAULTS_AUDIT_BEGIN|\(os)|catalog=\(MacSystemPreferencesCatalog.all.count)")

        for definition in MacSystemPreferencesCatalog.all {
            let status = audit(definition, client: client, version: version)
            counts[status, default: 0] += 1
        }

        let ordered: [AuditStatus] = [.pass, .unsupported, .restricted, .readFailed, .writeFailed, .readBackMismatch, .restoreFailed]
        let summary = ordered.map { "\($0.rawValue)=\(counts[$0, default: 0])" }.joined(separator: "|")
        print("DEFAULTS_AUDIT_SUMMARY|\(os)|\(summary)")

        let hardFailures = counts[.restoreFailed, default: 0]
        if hardFailures > 0 {
            fputs("Audit left one or more preferences unrestored.\n", stderr)
            exit(2)
        }
    }

    private static func audit(
        _ definition: SystemPreferenceDefinition,
        client: SystemDefaultsClient,
        version: OperatingSystemVersion
    ) -> AuditStatus {
        guard definition.isSupported(on: version) else {
            emit(definition, .unsupported, detail: "min-macos=\(definition.minimumMacOSMajorVersion)")
            return .unsupported
        }

        let original: SystemPreferenceValue
        do {
            original = try client.read(definition, timeout: 3)
        } catch SystemDefaultsClientError.accessDenied {
            emit(definition, .restricted, detail: "read-access-denied")
            return .restricted
        } catch {
            emit(definition, .readFailed, detail: sanitize(error.localizedDescription))
            return .readFailed
        }

        func restoreOriginal() -> Bool {
            do {
                try client.write(original, definition: definition, timeout: 3)
                return try client.read(definition, timeout: 3) == original
            } catch {
                return false
            }
        }

        func emitRestoreFailure(_ detail: String) -> AuditStatus {
            emit(definition, .restoreFailed, original: original, detail: detail)
            return .restoreFailed
        }

        do {
            try client.write(definition.recommendedValue, definition: definition, timeout: 3)
        } catch SystemDefaultsClientError.accessDenied {
            guard restoreOriginal() else {
                return emitRestoreFailure("restore-after-write-access-denied-failed")
            }
            emit(definition, .restricted, original: original, detail: "write-access-denied")
            return .restricted
        } catch {
            guard restoreOriginal() else {
                return emitRestoreFailure("restore-after-write-failed")
            }
            emit(definition, .writeFailed, original: original, detail: sanitize(error.localizedDescription))
            return .writeFailed
        }

        do {
            let readBack = try client.read(definition, timeout: 3)
            guard readBack == definition.recommendedValue else {
                guard restoreOriginal() else {
                    return emitRestoreFailure("restore-after-readback-mismatch-failed")
                }
                emit(
                    definition,
                    .readBackMismatch,
                    original: original,
                    detail: "wanted=\(describe(definition.recommendedValue)),got=\(describe(readBack))"
                )
                return .readBackMismatch
            }
        } catch {
            guard restoreOriginal() else {
                return emitRestoreFailure("restore-after-readback-error-failed")
            }
            emit(definition, .readBackMismatch, original: original, detail: "readback-error=\(sanitize(error.localizedDescription))")
            return .readBackMismatch
        }

        guard restoreOriginal() else {
            return emitRestoreFailure("restore-verification-failed")
        }

        emit(definition, .pass, original: original, detail: "probe=\(describe(definition.recommendedValue))")
        return .pass
    }

    private static func emit(
        _ definition: SystemPreferenceDefinition,
        _ status: AuditStatus,
        original: SystemPreferenceValue? = nil,
        detail: String
    ) {
        let originalText = original.map(describe) ?? "n/a"
        print(
            "DEFAULTS_AUDIT|\(status.rawValue)|\(definition.id)|\(definition.domain)|\(definition.key)|type=\(definition.valueType.rawValue)|original=\(originalText)|\(detail)"
        )
    }

    private static func describe(_ value: SystemPreferenceValue) -> String {
        switch value {
        case .missing: return "missing"
        case .bool(let value): return value ? "true" : "false"
        case .int(let value): return String(value)
        case .double(let value): return String(value)
        case .text(let value): return sanitize(value)
        }
    }

    private static func sanitize(_ value: String) -> String {
        value
            .replacingOccurrences(of: "|", with: "/")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }
}
