import SwiftUI

enum GatePassTheme {
    // A compact 4-point scale keeps every screen on the same visual rhythm.
    static let spaceXS: CGFloat = 4
    static let spaceS: CGFloat = 8
    static let spaceM: CGFloat = 12
    static let spaceL: CGFloat = 16
    static let spaceXL: CGFloat = 24

    static let pageInset = spaceXL
    static let sectionSpacing = spaceL
    static let panelPadding = spaceL
    static let sidebarWidth: CGFloat = 220
    static let panelRadius: CGFloat = 14
    static let rowRadius: CGFloat = 8
    static let contentMaxWidth: CGFloat = 1_080

    static var panelBackground: Color {
        Color(nsColor: .controlBackgroundColor)
    }

    static var rowBackground: Color {
        Color(nsColor: .windowBackgroundColor).opacity(0.72)
    }

    static var border: Color {
        Color(nsColor: .separatorColor).opacity(0.65)
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
                    .strokeBorder(GatePassTheme.border, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.025), radius: 8, y: 3)
    }
}

struct GatePassPageHeader<Accessory: View>: View {
    let title: String
    let subtitle: String
    private let accessory: Accessory

    init(
        title: String,
        subtitle: String,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory()
    }

    var body: some View {
        HStack(alignment: .center, spacing: GatePassTheme.spaceL) {
            VStack(alignment: .leading, spacing: GatePassTheme.spaceXS) {
                Text(title)
                    .font(.title2.weight(.semibold))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: GatePassTheme.spaceL)
            accessory
        }
        .padding(.horizontal, GatePassTheme.pageInset)
        .padding(.vertical, GatePassTheme.spaceL)
    }
}

extension GatePassPageHeader where Accessory == EmptyView {
    init(title: String, subtitle: String) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
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
            .font(.caption.weight(.semibold))
            .padding(.horizontal, GatePassTheme.spaceM)
            .frame(minHeight: 28)
            .background(color.opacity(0.1), in: Capsule())
    }
}
