//
//  CmdRunner.swift
//  GatePass
//
//

import Foundation
import AppKit
import SwiftUI


func removeQuarantine(path: String, sudo: Bool = false, appState: AppState) async {
    @AppStorage("gatepass.general.autoLaunch") var autoLaunch = true
    let fullCMD = "xattr -rd com.apple.quarantine '\(path)'"

    let out: TerminalOutput
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
        out = TerminalOutput(standardOutput: output, standardError: "")
    } else {
        out = runShCommand(fullCMD)
    }

    let removed = await checkQuarantineRemoved(path: path)
    if removed {
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
    } else if !sudo {
        printOS(out.standardError)
        updateOnMain {
            appState.status = "正在使用管理员权限重试"
        }
        await removeQuarantine(path: path, sudo: true, appState: appState)
    } else {
        printOS(out.standardError)
        updateOnMain {
            appState.status = "无法移除 App 的隔离标记"
        }
    }

    updateOnMain {
        appState.isLoading = false
    }
}


func checkQuarantineRemoved(path: String) async -> Bool {
    let out = runShCommand("xattr -p com.apple.quarantine '\(path)'")
    return out.standardOutput.isEmpty
}
