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
            GatePassPageHeader(
                title: gatePassCopy("设置", "Settings", language: language),
                subtitle: gatePassCopy(
                    "管理 GatePass 的通用选项、更新与应用信息。",
                    "Manage GatePass preferences, updates, and app information.",
                    language: language
                )
            )

            Divider()

            VStack(alignment: .leading, spacing: GatePassTheme.spaceL) {
                settingsTabPicker
                    .frame(maxWidth: .infinity, alignment: .center)

                settingsContent
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(.horizontal, GatePassTheme.pageInset)
            .padding(.vertical, GatePassTheme.spaceL)
            .frame(minWidth: 0, maxWidth: 920, maxHeight: .infinity, alignment: .topLeading)
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
        .controlSize(.large)
        .font(.callout.weight(.medium))
        .frame(width: 380, height: 36)
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
