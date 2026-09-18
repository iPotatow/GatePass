//
//  SettingsWindow.swift
//  GatePass
//
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var updater: GatePassUpdater
    @AppStorage(AppLanguage.storageKey) private var languageRaw = AppLanguage.system.rawValue
    @State private var selectedTabRaw = CurrentTabView.general.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    var body: some View {
        VStack(spacing: 0) {
            CorePageHeader(
                title: gatePassCopy("设置", "Settings", language: language)
            )

            CoreDivider()

            VStack(alignment: .leading, spacing: CoreSpacing.l) {
                settingsTabPicker
                    .frame(maxWidth: .infinity, alignment: .center)

                settingsContent
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(CoreSpacing.l)
            .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var settingsTabPicker: some View {
        Picker(
            "",
            selection: $selectedTabRaw
        ) {
            Label(gatePassCopy("通用", "General", language: language), systemImage: "gearshape")
                .tag(CurrentTabView.general.rawValue)
            Label(gatePassCopy("更新", "Updates", language: language), systemImage: "arrow.triangle.2.circlepath")
                .tag(CurrentTabView.update.rawValue)
            Label(gatePassCopy("关于", "About", language: language), systemImage: "info.circle")
                .tag(CurrentTabView.about.rawValue)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .font(CoreTypography.controlFont)
        .frame(width: 380, height: CoreMetrics.controlHeightDefault)
        .accessibilityLabel(gatePassCopy("设置页面", "Settings section", language: language))
    }

    @ViewBuilder
    private var settingsContent: some View {
        switch CurrentTabView(rawValue: selectedTabRaw) ?? .general {
        case .general:
            GeneralSettingsTab()
        case .update:
            UpdateSettingsTab()
        case .about:
            AboutView()
        }
    }
}

/// Legacy helper retained for older call sites. Settings are now presented inside the main GatePass window.
func openAppSettings() {
    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
}
