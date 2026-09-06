//
//  CmdRunner.swift
//  GatePass
//
//

import Foundation
import AppKit
import SwiftUI

private let quarantineAttribute = "com.apple.quarantine"

private struct XattrCommandResult: Sendable {
    let exitCode: Int32
    let output: String
}

private enum QuarantineVerification {
    case removed
    case stillPresent
    case failed(String)
}

func removeQuarantine(path: String, sudo: Bool = false, appState: AppState) async {
    @AppStorage("gatepass.general.autoLaunch") var autoLaunch = true

    let commandDiagnostic: String
    if sudo {
        let operation = GatePassAdminOperation.removeQuarantine(path: path)
        let (success, output) = await Task.detached(priority: .userInitiated) {
            performPrivileged(operation: operation)
        }.value
        guard success else {
            updateOnMain {
                appState.status = "操作已取消或失败"
                appState.isLoading = false
            }
            return
        }
        commandDiagnostic = output
    } else {
        do {
            let result = try await Task.detached(priority: .userInitiated) {
                try runXattrCommand([
                    "-r",
                    "-d",
                    quarantineAttribute,
                    path
                ])
            }.value
            commandDiagnostic = result.output
        } catch {
            commandDiagnostic = error.localizedDescription
        }
    }

    let verification = await verifyQuarantineRemoved(path: path)
    switch verification {
    case .removed:
        updateOnMain {
            appState.status = "已移除 App 的隔离标记"
            appState.doneQuarantine = true
            updateOnMain(after: 2) {
                appState.doneQuarantine = false
            }
        }
        if autoLaunch && !appState.multiDrop {
            NSWorkspace.shared.open(URL(fileURLWithPath: path))
        }

    case .stillPresent:
        let diagnostic = commandDiagnostic.isEmpty
            ? "com.apple.quarantine 仍然存在"
            : commandDiagnostic
        await retryWithPrivilegesOrFail(
            path: path,
            sudo: sudo,
            diagnostic: diagnostic,
            appState: appState
        )
        return

    case .failed(let verificationDiagnostic):
        let diagnostic = [commandDiagnostic, verificationDiagnostic]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        await retryWithPrivilegesOrFail(
            path: path,
            sudo: sudo,
            diagnostic: diagnostic,
            appState: appState
        )
        return
    }

    updateOnMain {
        appState.isLoading = false
    }
}

func checkQuarantineRemoved(path: String) async -> Bool {
    if case .removed = await verifyQuarantineRemoved(path: path) {
        return true
    }
    return false
}

private func retryWithPrivilegesOrFail(
    path: String,
    sudo: Bool,
    diagnostic: String,
    appState: AppState
) async {
    if !diagnostic.isEmpty {
        printOS(diagnostic)
    }

    if !sudo {
        updateOnMain {
            appState.status = "正在使用管理员权限重试"
        }
        await removeQuarantine(path: path, sudo: true, appState: appState)
        return
    }

    updateOnMain {
        appState.status = "无法移除 App 的隔离标记"
        appState.isLoading = false
    }
}

private func verifyQuarantineRemoved(path: String) async -> QuarantineVerification {
    do {
        let result = try await Task.detached(priority: .utility) {
            try runXattrCommand([
                "-p",
                quarantineAttribute,
                path
            ])
        }.value

        if result.exitCode == 0 {
            return .stillPresent
        }

        let output = result.output.lowercased()
        if output.contains("no such xattr") || output.contains("attribute not found") {
            return .removed
        }

        let diagnostic = result.output.isEmpty
            ? "xattr 验证失败，退出码：\(result.exitCode)"
            : result.output
        return .failed(diagnostic)
    } catch {
        return .failed(error.localizedDescription)
    }
}

private func runXattrCommand(_ arguments: [String]) throws -> XattrCommandResult {
    let process = Process()
    let outputPipe = Pipe()

    process.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
    process.arguments = arguments
    process.standardInput = FileHandle.nullDevice
    process.standardOutput = outputPipe
    process.standardError = outputPipe

    try process.run()

    // Drain output while the child is running so a noisy recursive xattr command
    // cannot block on a full pipe buffer before waitUntilExit() returns.
    let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()

    return XattrCommandResult(
        exitCode: process.terminationStatus,
        output: String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    )
}
