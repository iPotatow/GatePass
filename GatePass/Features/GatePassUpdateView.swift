import SwiftUI

struct GatePassStyledUpdateView: View {
    @ObservedObject var updater: GatePassUpdater
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: GatePassTheme.spaceL) {
            HStack {
                VStack(alignment: .leading, spacing: GatePassTheme.spaceXS) {
                    Text("GatePass Updates")
                        .gatePassTypography(GatePassTheme.typographySectionTitle)
                        .foregroundStyle(GatePassTheme.textPrimary)
                    Text("Installed: \(updater.displayVersion)")
                        .gatePassTypography(GatePassTheme.typographyCaption)
                        .foregroundStyle(GatePassTheme.textSecondary)
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
                        .gatePassTypography(GatePassTheme.typographyBody)
                        .foregroundStyle(GatePassTheme.textSecondary)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(GatePassTheme.semanticWarning)
                }
            } else if let release = updater.releases.first {
                Text("Latest release: \(release.tagName)")
                    .gatePassTypography(GatePassTheme.typographySectionTitle)
                    .foregroundStyle(GatePassTheme.textPrimary)

                if let notes = release.releaseNotes {
                    ScrollView {
                        Text(notes)
                            .gatePassTypography(GatePassTheme.typographyBody)
                            .foregroundStyle(GatePassTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 230)
                }
            } else {
                VStack(spacing: GatePassTheme.spaceS) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(GatePassTheme.textSecondary)
                    Text("No release information")
                        .gatePassTypography(GatePassTheme.typographyBody)
                        .foregroundStyle(GatePassTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if updater.isUpdating {
                VStack(alignment: .leading, spacing: GatePassTheme.spaceS) {
                    ProgressView(value: updater.progressBar.1)
                    Text(updater.progressBar.0)
                        .gatePassTypography(GatePassTheme.typographyCaption)
                        .foregroundStyle(GatePassTheme.textSecondary)
                }
            }

            HStack {
                Button("Close") { dismiss() }
                    .font(GatePassTheme.typeControl)
                Spacer()
                Button(updater.forceUpdateRequested ? "Reinstall" : "Update") {
                    updater.downloadUpdate()
                }
                .font(GatePassTheme.typeControl)
                .buttonStyle(.borderedProminent)
                .tint(GatePassTheme.accent)
                .disabled(
                    (!updater.hasNewerGatePassRelease && !updater.forceUpdateRequested)
                        || updater.isUpdating
                        || updater.isChecking
                )
            }
        }
        .padding(GatePassTheme.spaceXL)
        .frame(width: 560, height: 420)
    }
}
