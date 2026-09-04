//
//  AppState.swift
//  GatePass
//
//

import Foundation
import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()
    @Published var isGatekeeperAssessmentEnabled: Bool = true
    @Published var status: String = ""
    @Published var isLoading: Bool = false
    @Published var isScanningRecentApps = false
    @Published var multiDrop: Bool = false
    @Published var doneQuarantine: Bool = false
    @Published private(set) var recentApps: [RecentApp] = []


    init() {
        clearRetiredPreferences()
    }

    func refreshRecentApps() {
        guard !isScanningRecentApps else { return }

        isScanningRecentApps = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let apps = RecentAppsScanner.scanInstalledWithinLastWeek()
            DispatchQueue.main.async {
                guard let self else { return }
                self.recentApps = apps
                self.isScanningRecentApps = false
            }
        }
    }

    private func clearRetiredPreferences() {
        let defaults = UserDefaults.standard
        [
            "gatepass.general.codesignIdentity",
            "gatepass.general.notaryProfile",
            "gatepass.general.devCerts"
        ].forEach(defaults.removeObject(forKey:))
    }

}


enum CurrentTabView:Int
{
    case general
    case update
    case about

    var title: String {
        switch self {
        case .general: return "通用"
        case .update: return "更新"
        case .about: return "关于"
        }
    }
}

/// A lightweight app-level language preference. The preference is stored once
/// in UserDefaults so the main window and the Settings scene stay in sync.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    static let storageKey = "gatepass.general.language"

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .system: return resolved == .english ? Locale(identifier: "en") : Locale(identifier: "zh-Hans")
        case .simplifiedChinese: return Locale(identifier: "zh-Hans")
        case .english: return Locale(identifier: "en")
        }
    }

    var resolved: AppLanguage {
        guard self == .system else { return self }
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
        return preferred.hasPrefix("zh") ? .simplifiedChinese : .english
    }

    var isEnglish: Bool { resolved == .english }

    func displayName(in language: AppLanguage) -> String {
        switch self {
        case .system:
            return gatePassCopy("跟随系统", "System default", language: language)
        case .simplifiedChinese:
            return gatePassCopy("简体中文", "Simplified Chinese", language: language)
        case .english:
            return "English"
        }
    }
}

func gatePassCopy(_ simplifiedChinese: String, _ english: String, language: AppLanguage) -> String {
    language.isEnglish ? english : simplifiedChinese
}

func currentGatePassLanguage() -> AppLanguage {
    let stored = UserDefaults.standard.string(forKey: AppLanguage.storageKey) ?? AppLanguage.system.rawValue
    return AppLanguage(rawValue: stored) ?? .system
}

func localizedGatePassStatus(_ status: String, language: AppLanguage) -> String {
    guard language.isEnglish else { return status }

    let translations: [String: String] = [
        "正在移除 App 的隔离标记": "Removing the App quarantine attribute…",
        "正在移除 App 的隔离标记…": "Removing the App quarantine attribute…",
        "操作已取消或失败": "Operation canceled or failed",
        "已移除 App 的隔离标记": "Quarantine attribute removed",
        "正在使用管理员权限重试": "Retrying with administrator privileges",
        "无法移除 App 的隔离标记": "Unable to remove the App quarantine attribute",
        "Gatekeeper 评估已启用": "Gatekeeper assessment is enabled",
        "Gatekeeper 评估已关闭": "Gatekeeper assessment is disabled",
        "请在“隐私与安全性”>“安全性”中选择“App Store 和已知开发者”": "In Privacy & Security > Security, select “App Store and identified developers”",
        "请选择 .app 应用程序。": "Choose an .app application."
    ]

    if let translation = translations[status] {
        return translation
    }

    if status.contains("正在处理") {
        let count = status.filter(\.isNumber)
        if !count.isEmpty {
            return "Processing \(count) apps…"
        }
    }

    return status
}
