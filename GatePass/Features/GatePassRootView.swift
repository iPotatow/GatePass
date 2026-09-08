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
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

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
                .overlay {
                    if colorSchemeContrast == .increased {
                        RoundedRectangle(cornerRadius: GatePassTheme.contentRadius, style: .continuous)
                            .strokeBorder(GatePassTheme.border, lineWidth: 1)
                    }
                }
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
            focusedSection = section
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
    @Environment(\.colorSchemeContrast) private var contrast

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, GatePassTheme.navigationHorizontalPadding)
            .frame(height: GatePassTheme.navigationHeight)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                backgroundColor(isPressed: configuration.isPressed),
                in: RoundedRectangle(cornerRadius: GatePassTheme.rowRadius, style: .continuous)
            )
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: GatePassTheme.rowRadius, style: .continuous)
                        .stroke(GatePassTheme.focusRing, lineWidth: contrast == .increased ? 3 : 2)
                }
            }
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isPressed { return Color.accentColor.opacity(0.18) }
        if isSelected { return Color.accentColor.opacity(0.12) }
        if isHovered { return Color.primary.opacity(0.055) }
        return Color.clear
    }
}
