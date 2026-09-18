import SwiftUI

/// Kept as an internal engine compatibility type. The preference-mode UI has been removed.
enum SystemPreferenceMode: String, CaseIterable, Identifiable {
    case unchanged
    case smart
    case performance
    case privacy
    case manual

    var id: String { rawValue }
}
