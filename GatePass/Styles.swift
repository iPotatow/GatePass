import AppKit
import SwiftUI

struct GatePassTextStyle {
    let font: Font
    let tracking: CGFloat
    let lineSpacing: CGFloat

    init(
        size: CGFloat,
        weight: Font.Weight,
        nsWeight: NSFont.Weight,
        lineHeight: CGFloat,
        tracking: CGFloat
    ) {
        font = .system(size: size, weight: weight)
        self.tracking = tracking

        let nsFont = NSFont.systemFont(ofSize: size, weight: nsWeight)
        let defaultLineHeight = NSLayoutManager().defaultLineHeight(for: nsFont)
        lineSpacing = max(0, lineHeight - defaultLineHeight)
    }
}

enum GatePassTheme {
    // MARK: - Spacing

    static let spaceXS: CGFloat = 4
    static let spaceS: CGFloat = 8
    static let spaceM: CGFloat = 12
    static let spaceL: CGFloat = 16
    static let spaceXL: CGFloat = 24
    static let spaceXXL: CGFloat = 32

    // MARK: - Window & Layout

    static let windowWidth: CGFloat = 960
    static let windowHeight: CGFloat = 680

    static let sidebarWidth: CGFloat = 220
    static let sidebarPadding = spaceS
    static let sidebarTitlebarClearance = spaceXXL
    static let brandHeight: CGFloat = 56
    static let brandLogoSize: CGFloat = 40
    static let navigationHeight: CGFloat = 38
    static let navigationIconSize: CGFloat = 16
    static let navigationHorizontalPadding: CGFloat = 10

    static let contentInset = spaceS
    static let contentBodyPadding = spaceL
    static let pageInset = contentBodyPadding
    static let sectionSpacing = spaceL
    static let panelPadding = spaceL

    static let pageHeaderPaddingX = spaceXL
    static let pageHeaderPaddingTop: CGFloat = 36
    static let pageHeaderPaddingBottom = spaceL
    static let pageHeaderTitleActionGap = spaceL
    static let pageHeaderActionGap = spaceS

    static let controlHeightCompact: CGFloat = 28
    static let controlHeightSmall: CGFloat = 32
    static let controlHeightDefault: CGFloat = 36
    static let controlHeightLarge: CGFloat = 40
    static let controlHorizontalPadding: CGFloat = 12
    static let controlIconSize: CGFloat = 16

    static let dividerWidth: CGFloat = 0.5
    static let borderWidth: CGFloat = 1
    static let focusRingWidth: CGFloat = 2
    static let focusRingOffset: CGFloat = 2
    static let controlRowMinHeight: CGFloat = 40
    static let settingsRowMinHeight: CGFloat = 44

    static let dashboardPrimaryPanelMinWidth: CGFloat = 300
    static let dashboardRecentPanelMinWidth: CGFloat = 384

    static let contentRadius: CGFloat = 14
    static let panelRadius: CGFloat = 10
    static let rowRadius: CGFloat = 8
    static let contentMaxWidth: CGFloat = 1_080

    // MARK: - Typography

    static let typographyPageTitle = GatePassTextStyle(
        size: 24,
        weight: .semibold,
        nsWeight: .semibold,
        lineHeight: 30,
        tracking: -0.4
    )
    static let typographySectionTitle = GatePassTextStyle(
        size: 16,
        weight: .semibold,
        nsWeight: .semibold,
        lineHeight: 22,
        tracking: -0.1
    )
    static let typographyBody = GatePassTextStyle(
        size: 14,
        weight: .regular,
        nsWeight: .regular,
        lineHeight: 20,
        tracking: 0
    )
    static let typographyControl = GatePassTextStyle(
        size: 14,
        weight: .medium,
        nsWeight: .medium,
        lineHeight: 18,
        tracking: 0
    )
    static let typographyCaption = GatePassTextStyle(
        size: 12,
        weight: .regular,
        nsWeight: .regular,
        lineHeight: 16,
        tracking: 0
    )
    static let typographyGroupLabel = GatePassTextStyle(
        size: 12,
        weight: .medium,
        nsWeight: .medium,
        lineHeight: 16,
        tracking: 0.2
    )
    static let typographyBrand = GatePassTextStyle(
        size: 16,
        weight: .semibold,
        nsWeight: .semibold,
        lineHeight: 20,
        tracking: -0.1
    )

    // Font-only aliases remain for non-Text controls such as Label.
    static let typePageTitle = typographyPageTitle.font
    static let typeSectionTitle = typographySectionTitle.font
    static let typeBody = typographyBody.font
    static let typeControl = typographyControl.font
    static let typeCaption = typographyCaption.font
    static let typeGroupLabel = typographyGroupLabel.font
    static let typeBrand = typographyBrand.font

    // MARK: - Colors

    static let accent = adaptiveColor(light: (0, 122, 255), dark: (10, 132, 255))
    static let onAccent = adaptiveColor(light: (255, 255, 255), dark: (255, 255, 255))
    static let windowBackground = adaptiveColor(light: (244, 244, 245), dark: (28, 28, 30))
    static let sidebarBackground = adaptiveColor(light: (242, 242, 243), dark: (32, 32, 34))
    static let contentBackground = adaptiveColor(light: (255, 255, 255), dark: (36, 36, 38))
    static let panelBackground = adaptiveColor(light: (247, 247, 248), dark: (43, 43, 46))
    static let controlBackground = adaptiveColor(light: (255, 255, 255), dark: (50, 50, 53))
    static let controlHoverBackground = adaptiveColor(light: (243, 243, 244), dark: (58, 58, 61))
    static let controlPressedBackground = adaptiveColor(light: (234, 234, 236), dark: (66, 66, 69))

    static let textPrimary = adaptiveColor(light: (29, 29, 31), dark: (245, 245, 247))
    static let textSecondary = adaptiveColor(light: (110, 110, 115), dark: (174, 174, 178))
    static let textTertiary = adaptiveColor(light: (142, 142, 147), dark: (142, 142, 147))
    static let textDisabled = adaptiveColor(light: (174, 174, 178), dark: (99, 99, 102))

    static let divider = adaptiveColor(light: (220, 220, 224), dark: (58, 58, 60))
    static let border = adaptiveColor(light: (199, 199, 204), dark: (72, 72, 74))
    static let hoverOverlay = adaptiveColor(
        light: (0, 0, 0),
        dark: (255, 255, 255),
        lightAlpha: 0.05,
        darkAlpha: 0.06
    )
    static let pressedOverlay = adaptiveColor(
        light: (0, 0, 0),
        dark: (255, 255, 255),
        lightAlpha: 0.09,
        darkAlpha: 0.10
    )
    static let selectionBackground = adaptiveColor(
        light: (0, 122, 255),
        dark: (10, 132, 255),
        lightAlpha: 0.14,
        darkAlpha: 0.20
    )
    static let focusRing = adaptiveColor(
        light: (0, 122, 255),
        dark: (10, 132, 255),
        lightAlpha: 0.35,
        darkAlpha: 0.45
    )

    static let semanticSuccess = adaptiveColor(light: (36, 138, 61), dark: (48, 209, 88))
    static let semanticWarning = adaptiveColor(light: (255, 149, 0), dark: (255, 159, 10))
    static let semanticDanger = adaptiveColor(light: (255, 59, 48), dark: (255, 69, 58))
    static let semanticInfo = accent
    static let modalOverlay = adaptiveColor(
        light: (0, 0, 0),
        dark: (0, 0, 0),
        lightAlpha: 0.32,
        darkAlpha: 0.48
    )

    // Compatibility aliases for existing call sites.
    static let appBackground = windowBackground
    static let rowBackground = controlBackground

    // MARK: - State & Motion

    static let disabledOpacity: CGFloat = 0.45
    static let secondaryOpacity: CGFloat = 0.72
    static let tertiaryOpacity: CGFloat = 0.55

    static let motionFast = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.10)
    static let motionStandard = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.16)
    static let motionSlow = Animation.timingCurve(0.2, 0, 0, 1, duration: 0.22)
    static let motionEnter = Animation.timingCurve(0, 0, 0, 1, duration: 0.16)
    static let motionExit = Animation.timingCurve(0.4, 0, 1, 1, duration: 0.12)

    private static func adaptiveColor(
        light: (Int, Int, Int),
        dark: (Int, Int, Int),
        lightAlpha: CGFloat = 1,
        darkAlpha: CGFloat = 1
    ) -> Color {
        Color(
            nsColor: NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                let components = isDark ? dark : light
                let alpha = isDark ? darkAlpha : lightAlpha

                return NSColor(
                    srgbRed: CGFloat(components.0) / 255,
                    green: CGFloat(components.1) / 255,
                    blue: CGFloat(components.2) / 255,
                    alpha: alpha
                )
            }
        )
    }
}

extension Text {
    func gatePassTypography(_ style: GatePassTextStyle) -> some View {
        font(style.font)
            .tracking(style.tracking)
            .lineSpacing(style.lineSpacing)
    }
}

extension View {
    func gatePassContentSurfaceShadow() -> some View {
        background {
            RoundedRectangle(cornerRadius: GatePassTheme.contentRadius, style: .continuous)
                .fill(Color.black.opacity(0.10))
                .blur(radius: 3)
                .offset(y: 1)
        }
        .background {
            RoundedRectangle(cornerRadius: GatePassTheme.contentRadius, style: .continuous)
                .fill(Color.black.opacity(0.10))
                .padding(1)
                .blur(radius: 2)
                .offset(y: 1)
        }
    }
}

struct GatePassPanel<Content: View>: View {
    let padding: CGFloat
    @ViewBuilder let content: Content

    init(padding: CGFloat = GatePassTheme.panelPadding, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                GatePassTheme.panelBackground,
                in: RoundedRectangle(cornerRadius: GatePassTheme.panelRadius, style: .continuous)
            )
    }
}

struct GatePassPageHeader<Accessory: View>: View {
    let title: String
    private let accessory: Accessory

    init(
        title: String,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .center, spacing: GatePassTheme.pageHeaderTitleActionGap) {
            Text(title)
                .gatePassTypography(GatePassTheme.typographyPageTitle)
                .lineLimit(1)

            Spacer(minLength: GatePassTheme.pageHeaderTitleActionGap)

            accessory
                .font(GatePassTheme.typeControl)
                .frame(minHeight: GatePassTheme.controlHeightCompact)
        }
        .padding(.horizontal, GatePassTheme.pageHeaderPaddingX)
        .padding(.top, GatePassTheme.pageHeaderPaddingTop)
        .padding(.bottom, GatePassTheme.pageHeaderPaddingBottom)
    }
}

extension GatePassPageHeader where Accessory == EmptyView {
    init(title: String) {
        self.init(title: title) { EmptyView() }
    }
}

struct GatePassStatusPill: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label {
            Text(text)
                .gatePassTypography(GatePassTheme.typographyGroupLabel)
                .foregroundStyle(GatePassTheme.textPrimary)
        } icon: {
            Image(systemName: systemImage)
                .font(GatePassTheme.typeGroupLabel)
                .foregroundStyle(color)
        }
        .padding(.horizontal, GatePassTheme.spaceM)
        .frame(height: GatePassTheme.controlHeightCompact)
        .background(color.opacity(0.10), in: Capsule())
    }
}
