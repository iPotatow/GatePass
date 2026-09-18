import SwiftUI

struct GatePassStyledUpdateView: View {
    @ObservedObject var updater: GatePassUpdater
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: CoreSpacing.l) {
            HStack {
                VStack(alignment: .leading, spacing: CoreSpacing.xs) {
                    CoreSectionHeader(title: "GatePass Updates")
                    CoreSupportingText("Installed: \(updater.displayVersion)")
                }

                Spacer()

                if updater.isChecking {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            if let error = updater.updateError {
                Label {
                    Text(error)
                        .coreTypography(CoreTypography.body)
                        .foregroundStyle(CoreColor.textSecondary)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(CoreColor.warning)
                }
            } else if let release = updater.releases.first {
                CoreSectionHeader(title: "Latest release: \(release.tagName)")

                if let notes = release.releaseNotes {
                    ScrollView {
                        Text(notes)
                            .coreTypography(CoreTypography.body)
                            .foregroundStyle(CoreColor.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 230)
                }
            } else {
                CoreEmptyStateView(
                    title: "No release information",
                    systemImage: "shippingbox",
                    description: ""
                )
            }

            if updater.isUpdating {
                VStack(alignment: .leading, spacing: CoreSpacing.s) {
                    ProgressView(value: updater.progressBar.1)
                    CoreSupportingText(updater.progressBar.0)
                }
            }

            HStack {
                Button("Close") { dismiss() }
                    .font(CoreTypography.controlFont)

                Spacer()

                Button(updater.forceUpdateRequested ? "Reinstall" : "Update") {
                    updater.downloadUpdate()
                }
                .font(CoreTypography.controlFont)
                .buttonStyle(.borderedProminent)
                .tint(CoreColor.accent)
                .disabled(
                    (!updater.hasNewerGatePassRelease && !updater.forceUpdateRequested)
                        || updater.isUpdating
                        || updater.isChecking
                )
            }
        }
        .padding(CoreSpacing.xl)
        .frame(width: 560, height: 420)
    }
}
