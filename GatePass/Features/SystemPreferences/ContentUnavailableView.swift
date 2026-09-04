import SwiftUI

/// Small macOS 13-compatible empty-state component used by the System Preferences page.
struct GatePassEmptyStateView: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        VStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.callout.weight(.semibold))
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Kept as an internal engine compatibility type. The preference-mode UI has been removed.
enum SystemPreferenceMode: String, CaseIterable, Identifiable {
    case unchanged
    case smart
    case performance
    case privacy
    case manual

    var id: String { rawValue }
}
