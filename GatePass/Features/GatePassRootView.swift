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
    @FocusState private var focusedSection: GatePassMainSection?

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
                .background(GatePassTheme.sidebarBackground)
                .clipped()
                .layoutPriority(1)

            detail
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
                .background(
                    GatePassTheme.contentBackground,
                    in: RoundedRectangle(cornerRadius: GatePassTheme.contentRadius, style: .continuous)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: GatePassTheme.contentRadius, style: .continuous)
                )
                .gatePassContentSurfaceShadow()
                .padding(
                    EdgeInsets(
                        top: GatePassTheme.contentInset,
                        leading: 0,
                        bottom: GatePassTheme.contentInset,
                        trailing: GatePassTheme.contentInset
                    )
                )
        }
        .ignoresSafeArea(.container, edges: .top)
        .background(GatePassTheme.windowBackground)
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

            Spacer(minLength: GatePassTheme.spaceXL)
        }
        .padding(.top, GatePassTheme.sidebarTitlebarClearance)
        .padding(.horizontal, GatePassTheme.sidebarPadding)
        .padding(.bottom, GatePassTheme.sidebarPadding)
    }

    private var brand: some View {
        HStack(spacing: GatePassTheme.spaceS) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: GatePassTheme.brandLogoSize, height: GatePassTheme.brandLogoSize)
                .accessibilityHidden(true)

            Text("GatePass")
                .gatePassTypography(GatePassTheme.typographyBrand)
                .foregroundStyle(GatePassTheme.textPrimary)

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
            focusedSection = section
        } label: {
            HStack(spacing: GatePassTheme.spaceS) {
                Image(systemName: systemImage)
                    .font(.system(size: GatePassTheme.navigationIconSize, weight: .medium))
                    .frame(width: GatePassTheme.navigationIconSize)
                    .foregroundStyle(selected ? GatePassTheme.accent : GatePassTheme.textSecondary)

                Text(title)
                    .gatePassTypography(GatePassTheme.typographyControl)
                    .foregroundStyle(GatePassTheme.textPrimary)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .focused($focusedSection, equals: section)
        .buttonStyle(
            GatePassSidebarButtonStyle(
                isSelected: selected,
                isFocused: focusedSection == section
            )
        )
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct GatePassSidebarButtonStyle: ButtonStyle {
    let isSelected: Bool
    let isFocused: Bool

    @State private var isHovered = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, GatePassTheme.navigationHorizontalPadding)
            .frame(height: GatePassTheme.navigationHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? GatePassTheme.selectionBackground : Color.clear,
                in: RoundedRectangle(cornerRadius: GatePassTheme.rowRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: GatePassTheme.rowRadius, style: .continuous)
                    .fill(stateOverlay(isPressed: configuration.isPressed))
            }
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: GatePassTheme.rowRadius, style: .continuous)
                        .stroke(GatePassTheme.focusRing, lineWidth: GatePassTheme.focusRingWidth)
                        .padding(-GatePassTheme.focusRingOffset)
                }
            }
            .opacity(isEnabled ? 1 : GatePassTheme.disabledOpacity)
            .animation(reduceMotion ? nil : GatePassTheme.motionFast, value: configuration.isPressed)
            .animation(reduceMotion ? nil : GatePassTheme.motionFast, value: isHovered)
            .animation(reduceMotion ? nil : GatePassTheme.motionFast, value: isFocused)
            .onHover { isHovered = $0 }
    }

    private func stateOverlay(isPressed: Bool) -> Color {
        if isPressed { return GatePassTheme.pressedOverlay }
        if isHovered && !isSelected { return GatePassTheme.hoverOverlay }
        return .clear
    }
}
