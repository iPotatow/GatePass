import AppKit
import Foundation
import OSLog
import SwiftUI

extension Bundle {
    var name: String {
        (object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? "GatePass"
    }

    var version: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    var buildVersion: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
    }
}

enum GatePassLogCategory {
    static let general = "General"
    static let updater = "Updater"
}

final class GatePassLogStore: ObservableObject {
    static let shared = GatePassLogStore()

    @Published private(set) var logs: [String] = []

    private init() {}

    func addLog(_ message: String) {
        let update = { [weak self] in
            guard let self else { return }
            logs.append(message)
            if logs.count > 50 {
                logs.removeFirst(logs.count - 50)
            }
        }

        if Thread.isMainThread {
            update()
        } else {
            DispatchQueue.main.async(execute: update)
        }
    }

    func clearLogs() {
        let clear = { [weak self] in
            guard let self else { return }
            logs.removeAll()
        }
        if Thread.isMainThread {
            clear()
        } else {
            DispatchQueue.main.async(execute: clear)
        }
    }
}

func printOS(
    _ items: Any...,
    separator: String = " ",
    category: String = GatePassLogCategory.general,
    logType: OSLogType = .error
) {
    let message = items.map(String.init(describing:)).joined(separator: separator)
    let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.ipotatow.GatePass",
        category: category
    )
    logger.log(level: logType, "\(message, privacy: .public)")
    Swift.print(message)

    let formatter = DateFormatter()
    formatter.dateFormat = "[MMM d, h:mm:ss a]"
    GatePassLogStore.shared.addLog("\(formatter.string(from: Date())) \(message)")
}

func updateOnMain(after delay: Double? = nil, _ updates: @escaping () -> Void) {
    if let delay {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: updates)
    } else {
        DispatchQueue.main.async(execute: updates)
    }
}

struct DebugConsoleView: View {
    @ObservedObject private var logStore = GatePassLogStore.shared
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Console Logs")
                    .font(.headline)
                Spacer()
                Button {
                    copyAllLogs()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(logStore.logs.isEmpty)
                .help(copied ? "Copied" : "Copy all logs")

                Button {
                    logStore.clearLogs()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(logStore.logs.isEmpty)
                .help("Clear all logs")
            }
            .padding()

            if logStore.logs.isEmpty {
                Text("No logs available to view")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(logStore.logs.indices.reversed(), id: \.self) { index in
                    Text(logStore.logs[index])
                        .font(.system(size: 12, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .onTapGesture {
                            copy(logStore.logs[index])
                        }
                }
            }

            if copied {
                Text("Copied to clipboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
        }
        .frame(minWidth: 560, minHeight: 340)
    }

    private func copyAllLogs() {
        copy(logStore.logs.joined(separator: "\n"))
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}

final class DebugConsoleWindowController {
    static let shared = DebugConsoleWindowController()

    private var window: NSWindow?

    func open() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(contentViewController: NSHostingController(rootView: DebugConsoleView()))
        window.title = "Debug Console"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.setContentSize(NSSize(width: 600, height: 400))
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}

enum GatePassAdminOperation {
    case removeQuarantine(path: String)

    fileprivate var shellCommand: String {
        switch self {
        case let .removeQuarantine(path):
            return "/usr/bin/xattr -rd com.apple.quarantine \(shellQuote(path))"
        }
    }
}

func performPrivileged(operation: GatePassAdminOperation) -> (success: Bool, output: String) {
    let script = "do shell script \(appleScriptString(operation.shellCommand)) with administrator privileges"
    let process = Process()
    let outputPipe = Pipe()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]
    process.standardOutput = outputPipe
    process.standardError = outputPipe

    do {
        try process.run()
        process.waitUntilExit()
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return (process.terminationStatus == 0, output)
    } catch {
        return (false, error.localizedDescription)
    }
}

private func shellQuote(_ value: String) -> String {
    "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
}

private func appleScriptString(_ value: String) -> String {
    let escaped = value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\""
}
