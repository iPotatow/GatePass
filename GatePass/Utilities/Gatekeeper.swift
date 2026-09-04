//
//  Gatekeeper.swift
//  GatePass
//
//
import Foundation

/// Refreshes the read-only Gatekeeper assessment status shown in the dashboard.
/// The app deliberately does not change the global security policy. Users can
/// choose “App Store and identified developers” in macOS System Settings.
func updateGatekeeperUI(appState: AppState) {
    Task {
        let isEnabled = await getGatekeeperStatus()

        await MainActor.run {
            appState.isGatekeeperAssessmentEnabled = isEnabled
        }
    }
}

func getGatekeeperStatus() async -> Bool {
    let out = runShCommand("spctl --status")
    let disabled = out.standardError.lowercased().contains("disabled")
    let enabled = out.standardOutput.lowercased().contains("enabled")
    return enabled && !disabled
}
