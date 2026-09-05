import Foundation

enum SystemDefaultsClientError: Error, LocalizedError {
    case timedOut
    case accessDenied
    case invalidBoolean
    case invalidInteger
    case invalidFloatingPoint
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .timedOut: return "系统偏好读取超时"
        case .accessDenied: return "系统拒绝访问此偏好设置"
        case .invalidBoolean: return "系统偏好返回了无效布尔值"
        case .invalidInteger: return "系统偏好返回了无效整数"
        case .invalidFloatingPoint: return "系统偏好返回了无效浮点数"
        case .commandFailed(let message): return message.isEmpty ? "系统偏好操作失败" : message
        }
    }
}

protocol SystemDefaultsAccess: Sendable {
    func read(_ definition: SystemPreferenceDefinition, timeout: TimeInterval) throws -> SystemPreferenceValue
    func write(_ value: SystemPreferenceValue, definition: SystemPreferenceDefinition, timeout: TimeInterval) throws
}

struct SystemDefaultsClient: SystemDefaultsAccess, Sendable {
    func read(_ definition: SystemPreferenceDefinition, timeout: TimeInterval = 2) throws -> SystemPreferenceValue {
        let result = try run(arguments: ["read", definition.domain, definition.key], timeout: timeout)
        if result.exitCode != 0 {
            if isAccessDenied(result.stderr) { throw SystemDefaultsClientError.accessDenied }
            return .missing
        }

        let text = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        switch definition.valueType {
        case .boolean:
            switch text.lowercased() {
            case "1", "true", "yes": return .bool(true)
            case "0", "false", "no": return .bool(false)
            default: throw SystemDefaultsClientError.invalidBoolean
            }
        case .integer:
            guard let value = Int(text) else { throw SystemDefaultsClientError.invalidInteger }
            return .int(value)
        case .floatingPoint:
            guard let value = Double(text) else { throw SystemDefaultsClientError.invalidFloatingPoint }
            return .double(value)
        case .text:
            return .text(text)
        }
    }

    func write(_ value: SystemPreferenceValue, definition: SystemPreferenceDefinition, timeout: TimeInterval = 2) throws {
        let arguments: [String]
        switch value {
        case .missing:
            arguments = ["delete", definition.domain, definition.key]
        case .bool(let value):
            arguments = ["write", definition.domain, definition.key, "-bool", value ? "true" : "false"]
        case .int(let value):
            arguments = ["write", definition.domain, definition.key, "-int", String(value)]
        case .double(let value):
            arguments = ["write", definition.domain, definition.key, "-float", String(value)]
        case .text(let value):
            arguments = ["write", definition.domain, definition.key, "-string", value]
        }

        let result = try run(arguments: arguments, timeout: timeout)
        guard result.exitCode == 0 else {
            if isAccessDenied(result.stderr) { throw SystemDefaultsClientError.accessDenied }
            if case .missing = value, (try? read(definition, timeout: timeout)) == .missing { return }
            throw SystemDefaultsClientError.commandFailed(result.stderr.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private func isAccessDenied(_ text: String) -> Bool {
        let value = text.lowercased()
        return value.contains("not permitted") || value.contains("permission denied") || value.contains("operation not permitted")
    }

    private func run(arguments: [String], timeout: TimeInterval) throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = arguments
        process.standardInput = FileHandle.nullDevice

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()

        // Drain both pipes while the process is running. Waiting for the child
        // before reading can deadlock when defaults emits enough diagnostics to
        // fill a pipe buffer.
        let output = CommandOutputBuffer()
        let readers = DispatchGroup()
        readers.enter()
        DispatchQueue.global(qos: .utility).async {
            output.setStdout(stdout.fileHandleForReading.readDataToEndOfFile())
            readers.leave()
        }
        readers.enter()
        DispatchQueue.global(qos: .utility).async {
            output.setStderr(stderr.fileHandleForReading.readDataToEndOfFile())
            readers.leave()
        }

        let deadline = Date().addingTimeInterval(max(0.1, timeout))
        while process.isRunning {
            if Date() >= deadline {
                process.terminate()
                process.waitUntilExit()
                readers.wait()
                throw SystemDefaultsClientError.timedOut
            }
            Thread.sleep(forTimeInterval: 0.01)
        }
        readers.wait()

        return CommandResult(
            exitCode: process.terminationStatus,
            stdout: String(data: output.stdout, encoding: .utf8) ?? "",
            stderr: String(data: output.stderr, encoding: .utf8) ?? ""
        )
    }
}


private final class CommandOutputBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var stdoutData = Data()
    private var stderrData = Data()

    func setStdout(_ data: Data) {
        lock.lock()
        stdoutData = data
        lock.unlock()
    }

    func setStderr(_ data: Data) {
        lock.lock()
        stderrData = data
        lock.unlock()
    }

    var stdout: Data {
        lock.lock()
        defer { lock.unlock() }
        return stdoutData
    }

    var stderr: Data {
        lock.lock()
        defer { lock.unlock() }
        return stderrData
    }
}

private struct CommandResult {
    let exitCode: Int32
    let stdout: String
    let stderr: String
}
