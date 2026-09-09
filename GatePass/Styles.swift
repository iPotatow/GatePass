import SwiftUI

enum GatePassTheme {
    // macOS Core v5 spacing grid.
    static let spaceXS: CGFloat = 4
    static let spaceS: CGFloat = 8
    static let spaceM: CGFloat = 12
    static let spaceL: CGFloat = 16
    static let spaceXL: CGFloat = 24
    static let spaceXXL: CGFloat = 32

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

    static let dividerWidth: CGFloat = 0.5
    static let borderWidth: CGFloat = 1
    static let controlRowMinHeight: CGFloat = 40
    static let settingsRowMinHeight: CGFloat = 44

    static let typePageTitle = Font.system(size: 24, weight: .semibold)
    static let typeSectionTitle = Font.system(size: 16, weight: .semibold)
    static let typeBody = Font.system(size: 14, weight: .regular)
    static let typeControl = Font.system(size: 14, weight: .medium)
    static let typeCaption = Font.system(size: 12, weight: .regular)
    static let typeGroupLabel = Font.system(size: 12, weight: .medium)

    static let dashboardPrimaryPanelMinWidth: CGFloat = 300
    static let dashboardRecentPanelMinWidth: CGFloat = 384

    static let contentRadius: CGFloat = 14
    static let panelRadius: CGFloat = 10
    static let rowRadius: CGFloat = 8
    static let contentMaxWidth: CGFloat = 1_080

    static var panelBackground: Color {
        Color(nsColor: .controlBackgroundColor)
    }

    static var appBackground: Color {
        Color(nsColor: .underPageBackgroundColor)
    }

    static var contentBackground: Color {
        Color(nsColor: .windowBackgroundColor)
    }

    static var rowBackground: Color {
        Color(nsColor: .windowBackgroundColor).opacity(0.72)
    }

    static var border: Color {
        Color(nsColor: .separatorColor).opacity(0.65)
    }

    static var focusRing: Color {
        Color(nsColor: .keyboardFocusIndicatorColor)
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
            .overlay {
                RoundedRectangle(cornerRadius: GatePassTheme.panelRadius, style: .continuous)
                    .strokeBorder(GatePassTheme.border, lineWidth: GatePassTheme.borderWidth)
            }
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
                .font(GatePassTheme.typePageTitle)
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
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(color)
        }
        .font(GatePassTheme.typeGroupLabel)
        .padding(.horizontal, GatePassTheme.spaceM)
        .frame(height: GatePassTheme.controlHeightCompact)
        .background(color.opacity(0.1), in: Capsule())
    }
}
