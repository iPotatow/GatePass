import SwiftUI

// GatePass-only product geometry. Reusable visual tokens and components live in CoreUI.
enum GatePassLayout {
    static let windowWidth: CGFloat = 960
    static let windowHeight: CGFloat = 680

    static let sidebarWidth: CGFloat = 220
    static let sidebarPadding = CoreSpacing.s
    static let sidebarTitlebarClearance = CoreSpacing.xxl
    static let brandHeight: CGFloat = 56
    static let brandLogoSize: CGFloat = 40
    static let navigationHeight: CGFloat = 38
    static let navigationHorizontalPadding: CGFloat = 10

    // Content Surface hard constraint: top/right/bottom/left = 8/8/8/0.
    static let contentSurfaceInset = CoreSpacing.s

    static let dashboardPrimaryPanelMinWidth: CGFloat = 300
    static let dashboardRecentPanelMinWidth: CGFloat = 384
    static let contentMaxWidth: CGFloat = 1_080
}
