import Foundation
import OSLog

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case simplifiedChinese = "zh-Hans"
    case english = "en"
    var id: String { rawValue }
    var locale: Locale { Locale(identifier: "en") }
    func displayName(in language: AppLanguage) -> String { "" }
}

func gatePassCopy(_ zhHans: String, _ english: String, language: AppLanguage) -> String {
    language == .english ? english : zhHans
}
