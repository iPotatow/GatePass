import SwiftUI

// MARK: - Surface

extension View {
    func coreContentSurfaceShadow() -> some View {
        background {
            RoundedRectangle(cornerRadius: CoreRadius.content, style: .continuous)
                .fill(Color.black.opacity(0.10))
                .blur(radius: 3)
                .offset(y: 1)
        }
        .background {
            RoundedRectangle(cornerRadius: CoreRadius.content, style: .continuous)
                .fill(Color.black.opacity(0.10))
                .padding(1)
                .blur(radius: 2)
                .offset(y: 1)
        }
    }
}

struct CorePanel<Content: View>: View {
    let padding: CGFloat
    @ViewBuilder let content: Content

    init(
        padding: CGFloat = CoreMetrics.panelPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                CoreColor.panelBackground,
                in: RoundedRectangle(cornerRadius: CoreRadius.panel, style: .continuous)
            )
    }
}

// MARK: - Page Header

struct CorePageHeader<Accessory: View>: View {
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
        HStack(alignment: .center, spacing: CoreMetrics.pageHeaderTitleActionGap) {
            Text(title)
                .coreTypography(CoreTypography.pageTitle)
                .lineLimit(1)

            Spacer(minLength: CoreMetrics.pageHeaderTitleActionGap)

            accessory
                .font(CoreTypography.controlFont)
                .frame(minHeight: CoreMetrics.controlHeightCompact)
        }
        .padding(.horizontal, CoreMetrics.pageHeaderPaddingX)
        .padding(.top, CoreMetrics.pageHeaderPaddingTop)
        .padding(.bottom, CoreMetrics.pageHeaderPaddingBottom)
    }
}

extension CorePageHeader where Accessory == EmptyView {
    init(title: String) {
        self.init(title: title) { EmptyView() }
    }
}

// MARK: - Status

struct CoreStatusPill: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label {
            Text(text)
                .coreTypography(CoreTypography.groupLabel)
                .foregroundStyle(CoreColor.textPrimary)
        } icon: {
            Image(systemName: systemImage)
                .font(CoreTypography.groupLabelFont)
                .foregroundStyle(color)
        }
        .padding(.horizontal, CoreSpacing.m)
        .frame(height: CoreMetrics.controlHeightCompact)
        .background(color.opacity(0.10), in: Capsule())
    }
}

// MARK: - Divider

struct CoreDivider: View {
    var body: some View {
        Rectangle()
            .fill(CoreColor.divider)
            .frame(height: CoreMetrics.dividerWidth)
            .accessibilityHidden(true)
    }
}
