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
                .background(Color(nsColor: .underPageBackgroundColor))
                .clipped()
                .layoutPriority(1)

            Divider()

            detail
                .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(nsColor: .windowBackgroundColor))
                .clipped()
        }
        .frame(minWidth: 820, minHeight: 620, alignment: .topLeading)
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

            VStack(spacing: 6) {
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
            .padding(.horizontal, 14)

            Spacer(minLength: 20)
        }
    }

    private var brand: some View {
        VStack(spacing: 6) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .accessibilityHidden(true)

            Text("GatePass")
                .font(.title3.weight(.bold))

            Text(gatePassCopy("macOS 实用工具", "macOS utility", language: language))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 58)
        .padding(.bottom, 28)
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
            HStack(spacing: 11) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 22)
                    .foregroundStyle(selected ? Color.accentColor : Color.secondary)

                Text(title)
                    .font(.system(size: 15, weight: selected ? .semibold : .medium))
                    .foregroundStyle(Color.primary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .contentShape(Rectangle())
            .background(
                selected ? Color.accentColor.opacity(0.11) : Color.clear,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

}
