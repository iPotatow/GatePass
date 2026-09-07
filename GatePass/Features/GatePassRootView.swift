import SwiftUI

enum GatePassMainSection: Hashable {
    case appRelease
    case systemPreferences
    case settings
}

struct GatePassRootView: View {
    @State private var selection: GatePassMainSection = .appRelease
    @StateObject private var preferencesStore = SystemPreferencesStore.live()
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(
                    minWidth: GatePassTheme.sidebarWidth,
                    maxWidth: GatePassTheme.sidebarWidth,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
                .clipped()
                .layoutPriority(1)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: GatePassTheme.panelRadius, style: .continuous)
                    .fill(GatePassTheme.contentBackground)

                detail
                    .clipShape(RoundedRectangle(cornerRadius: GatePassTheme.panelRadius, style: .continuous))
            }
                .overlay {
                    RoundedRectangle(cornerRadius: GatePassTheme.panelRadius, style: .continuous)
                        .strokeBorder(GatePassTheme.border.opacity(0.7), lineWidth: 1)
                }
                .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
                .padding(
                    EdgeInsets(
                        top: GatePassTheme.contentInset,
                        leading: 0,
                        bottom: GatePassTheme.contentInset,
                        trailing: GatePassTheme.contentInset
                    )
                )
                .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .ignoresSafeArea(.container, edges: .top)
        .background(GatePassTheme.appBackground)
        .frame(
            minWidth: GatePassTheme.windowWidth,
            minHeight: GatePassTheme.windowHeight,
            alignment: .topLeading
        )
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .appRelease:
            Dashboard()
        case .systemPreferences:
            SystemPreferencesView(store: preferencesStore)
        case .settings:
            SettingsView()
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            brand

            VStack(spacing: GatePassTheme.spaceXS) {
                sidebarButton(
                    section: .appRelease,
                    title: gatePassCopy("APP放行", "App Access", language: language),
                    systemImage: "lock.open.fill"
                )

                sidebarButton(
                    section: .systemPreferences,
                    title: gatePassCopy("系统偏好", "System Preferences", language: language),
                    systemImage: "slider.horizontal.3"
                )

                sidebarButton(
                    section: .settings,
                    title: gatePassCopy("设置", "Settings", language: language),
                    systemImage: "gearshape.fill"
                )
            }
            .padding(.top, GatePassTheme.spaceS)

            Spacer(minLength: 20)
        }
        .padding(GatePassTheme.sidebarPadding)
        .padding(.top, 26)
    }

    private var brand: some View {
        HStack(spacing: GatePassTheme.spaceS) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: GatePassTheme.brandLogoSize, height: GatePassTheme.brandLogoSize)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)

            Text("GatePass")
                .font(.system(size: 16, weight: .semibold))

            Spacer(minLength: 0)
        }
        .frame(height: GatePassTheme.brandHeight)
        .padding(.horizontal, GatePassTheme.spaceS)
    }

    private func sidebarButton(
        section: GatePassMainSection,
        title: String,
        systemImage: String
    ) -> some View {
        let selected = selection == section

        return Button {
            selection = section
        } label: {
            HStack(spacing: GatePassTheme.spaceS) {
                Image(systemName: systemImage)
                    .font(.system(size: GatePassTheme.navigationIconSize, weight: .medium))
                    .frame(width: GatePassTheme.navigationIconSize)
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)

                Text(title)
                    .font(.system(size: 14, weight: selected ? .semibold : .medium))
                    .foregroundStyle(Color.primary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(height: GatePassTheme.navigationHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(GatePassSidebarButtonStyle(isSelected: selected))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

}

private struct GatePassSidebarButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                backgroundColor(isPressed: configuration.isPressed),
                in: RoundedRectangle(cornerRadius: GatePassTheme.rowRadius, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isPressed { return Color.accentColor.opacity(0.18) }
        if isSelected { return Color.accentColor.opacity(0.12) }
        return Color.clear
    }
}
