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
                    minWidth: GatePassLayout.sidebarWidth,
                    maxWidth: GatePassLayout.sidebarWidth,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
                .background(CoreColor.sidebarBackground)
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
                    CoreColor.contentBackground,
                    in: RoundedRectangle(cornerRadius: CoreRadius.content, style: .continuous)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: CoreRadius.content, style: .continuous)
                )
                .coreContentSurfaceShadow()
                .padding(
                    EdgeInsets(
                        top: GatePassLayout.contentSurfaceInset,
                        leading: 0,
                        bottom: GatePassLayout.contentSurfaceInset,
                        trailing: GatePassLayout.contentSurfaceInset
                    )
                )
        }
        .ignoresSafeArea(.container, edges: .top)
        .background(CoreColor.windowBackground)
        .frame(
            minWidth: GatePassLayout.windowWidth,
            minHeight: GatePassLayout.windowHeight,
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

            VStack(spacing: CoreSpacing.xs) {
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
            .padding(.top, CoreSpacing.s)

            Spacer(minLength: CoreSpacing.xl)
        }
        .padding(.top, GatePassLayout.sidebarTitlebarClearance)
        .padding(.horizontal, GatePassLayout.sidebarPadding)
        .padding(.bottom, GatePassLayout.sidebarPadding)
    }

    private var brand: some View {
        HStack(spacing: CoreSpacing.s) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: GatePassLayout.brandLogoSize, height: GatePassLayout.brandLogoSize)
                .accessibilityHidden(true)

            Text("GatePass")
                .coreTypography(CoreTypography.brand)
                .foregroundStyle(CoreColor.textPrimary)

            Spacer(minLength: 0)
        }
        .frame(height: GatePassLayout.brandHeight)
        .padding(.horizontal, CoreSpacing.s)
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
            HStack(spacing: CoreSpacing.s) {
                Image(systemName: systemImage)
                    .font(.system(size: CoreMetrics.controlIconSize, weight: .medium))
                    .frame(width: CoreMetrics.controlIconSize)
                    .foregroundStyle(selected ? CoreColor.accent : CoreColor.textSecondary)

                Text(title)
                    .coreTypography(CoreTypography.control)
                    .foregroundStyle(CoreColor.textPrimary)

                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .focused($focusedSection, equals: section)
        .buttonStyle(
            CoreSidebarButtonStyle(
                isSelected: selected,
                isFocused: focusedSection == section,
                height: GatePassLayout.navigationHeight,
                horizontalPadding: GatePassLayout.navigationHorizontalPadding,
                cornerRadius: CoreRadius.row
            )
        )
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
