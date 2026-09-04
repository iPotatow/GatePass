import Foundation

enum SystemPreferenceValue: Equatable, Codable, Sendable {
    case missing
    case bool(Bool)
    case int(Int)
    case double(Double)
    case text(String)

    private enum CodingKeys: String, CodingKey { case type, bool, int, double, text }
    private enum Kind: String, Codable { case missing, bool, int, double, text }

    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        switch try box.decode(Kind.self, forKey: .type) {
        case .missing: self = .missing
        case .bool: self = .bool(try box.decode(Bool.self, forKey: .bool))
        case .int: self = .int(try box.decode(Int.self, forKey: .int))
        case .double: self = .double(try box.decode(Double.self, forKey: .double))
        case .text: self = .text(try box.decode(String.self, forKey: .text))
        }
    }

    func encode(to encoder: Encoder) throws {
        var box = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .missing:
            try box.encode(Kind.missing, forKey: .type)
        case .bool(let value):
            try box.encode(Kind.bool, forKey: .type)
            try box.encode(value, forKey: .bool)
        case .int(let value):
            try box.encode(Kind.int, forKey: .type)
            try box.encode(value, forKey: .int)
        case .double(let value):
            try box.encode(Kind.double, forKey: .type)
            try box.encode(value, forKey: .double)
        case .text(let value):
            try box.encode(Kind.text, forKey: .type)
            try box.encode(value, forKey: .text)
        }
    }
}

enum SystemPreferenceValueType: String, Codable, Sendable {
    case boolean
    case integer
    case floatingPoint
    case text
}

enum SystemPreferenceCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case performance
    case productivity
    case privacy
    case storage
    case appearance

    var id: String { rawValue }
}

enum SystemPreferenceComponent: String, CaseIterable, Identifiable, Sendable {
    case finder
    case dock
    case safari
    case keyboard
    case textInput
    case screenshots
    case windows
    case desktop
    case missionControl
    case activityMonitor
    case appStore
    case timeMachine
    case textEdit
    case photos
    case printing
    case sharing
    case privacy
    case sound
    case security
    case system

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .finder: return "folder.fill"
        case .dock: return "dock.rectangle"
        case .safari: return "safari.fill"
        case .keyboard: return "keyboard.fill"
        case .textInput: return "text.cursor"
        case .screenshots: return "camera.viewfinder"
        case .windows: return "macwindow"
        case .desktop: return "desktopcomputer"
        case .missionControl: return "rectangle.3.group.fill"
        case .activityMonitor: return "waveform.path.ecg.rectangle.fill"
        case .appStore: return "bag.fill"
        case .timeMachine: return "clock.arrow.circlepath"
        case .textEdit: return "doc.text.fill"
        case .photos: return "photo.fill"
        case .printing: return "printer.fill"
        case .sharing: return "square.and.arrow.up.fill"
        case .privacy: return "hand.raised.fill"
        case .sound: return "speaker.wave.2.fill"
        case .security: return "lock.shield.fill"
        case .system: return "gearshape.2.fill"
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .finder: return gatePassCopy("访达", "Finder", language: language)
        case .dock: return gatePassCopy("Dock 栏", "Dock", language: language)
        case .safari: return "Safari"
        case .keyboard: return gatePassCopy("键盘", "Keyboard", language: language)
        case .textInput: return gatePassCopy("文本输入", "Text Input", language: language)
        case .screenshots: return gatePassCopy("截图", "Screenshots", language: language)
        case .windows: return gatePassCopy("窗口", "Windows", language: language)
        case .desktop: return gatePassCopy("桌面", "Desktop", language: language)
        case .missionControl: return gatePassCopy("调度中心", "Mission Control", language: language)
        case .activityMonitor: return gatePassCopy("活动监视器", "Activity Monitor", language: language)
        case .appStore: return "App Store"
        case .timeMachine: return "Time Machine"
        case .textEdit: return "TextEdit"
        case .photos: return gatePassCopy("照片", "Photos", language: language)
        case .printing: return gatePassCopy("打印", "Printing", language: language)
        case .sharing: return gatePassCopy("共享", "Sharing", language: language)
        case .privacy: return gatePassCopy("隐私", "Privacy", language: language)
        case .sound: return gatePassCopy("声音", "Sound", language: language)
        case .security: return gatePassCopy("安全", "Security", language: language)
        case .system: return gatePassCopy("系统", "System", language: language)
        }
    }
}

enum SystemPreferenceSelectionKind: String, Codable, Sendable {
    case oneClick
    case custom
}

enum SystemPreferenceRiskLevel: String, Codable, Sendable {
    case standard
    case caution
    case high
}

enum SystemPreferenceStatus: String, Codable, Sendable {
    case recommended
    case optimized
    case unavailable
}

enum SystemPreferenceDiagnostic: String, Codable, Sendable {
    case unsupported
    case accessDenied
    case stateUnavailable
}

struct SystemPreferenceDefinition: Identifiable, Sendable {
    let id: String
    let titleZH: String
    let titleEN: String
    let summaryZH: String
    let summaryEN: String
    let category: SystemPreferenceCategory
    let selectionKind: SystemPreferenceSelectionKind
    let riskLevel: SystemPreferenceRiskLevel
    let domain: String
    let key: String
    let valueType: SystemPreferenceValueType
    let defaultValue: SystemPreferenceValue
    let recommendedValue: SystemPreferenceValue
    let disabledValue: SystemPreferenceValue?
    let requiresRestart: Bool

    func title(language: AppLanguage) -> String {
        gatePassCopy(titleZH, titleEN, language: language)
    }

    func summary(language: AppLanguage) -> String {
        gatePassCopy(summaryZH, summaryEN, language: language)
    }

    var component: SystemPreferenceComponent {
        if id.hasPrefix("macos.finder.") { return .finder }
        if id.hasPrefix("macos.dock.") { return .dock }
        if id.hasPrefix("macos.safari.") { return .safari }
        if id.hasPrefix("macos.keyboard.") { return .keyboard }
        if id.hasPrefix("macos.text.") { return .textInput }
        if id.hasPrefix("macos.screenshots.") { return .screenshots }
        if id.hasPrefix("macos.window.") { return .windows }
        if id.hasPrefix("macos.desktop.") { return .desktop }
        if id.hasPrefix("macos.mission-control.") { return .missionControl }
        if id.hasPrefix("macos.activity-monitor.") { return .activityMonitor }
        if id.hasPrefix("macos.app-store.") { return .appStore }
        if id.hasPrefix("macos.time-machine.") { return .timeMachine }
        if id.hasPrefix("macos.textedit.") { return .textEdit }
        if id.hasPrefix("macos.photos.") { return .photos }
        if id.hasPrefix("macos.printing.") { return .printing }
        if id.hasPrefix("macos.sharing.") { return .sharing }
        if id.hasPrefix("macos.privacy.") { return .privacy }
        if id.hasPrefix("macos.sound.") { return .sound }
        if id.hasPrefix("macos.security.") { return .security }
        return .system
    }
}

struct SystemPreferenceItem: Identifiable, Sendable {
    var id: String { definition.id }
    let definition: SystemPreferenceDefinition
    let currentValue: SystemPreferenceValue
    let status: SystemPreferenceStatus
    let diagnostic: SystemPreferenceDiagnostic?
    let restoreAvailable: Bool
}

struct SystemPreferencesCatalog: Sendable {
    let scanID: UUID
    let revision: String
    let scannedAt: Date
    let elapsed: TimeInterval
    let items: [SystemPreferenceItem]
    let recoveryAvailable: Bool

    var optimizedIDs: Set<String> {
        Set(items.filter { $0.status == .optimized }.map(\.id))
    }
}

enum SystemPreferenceTargetState: String, Codable, Sendable {
    case optimized
    case systemDefault
}

enum SystemPreferenceSkipReason: String, Codable, Sendable {
    case alreadyOptimized
    case alreadyDefault
    case settingChanged
    case settingMissing
    case stateUnavailable
    case unsupported
}

struct SystemPreferenceChangePlanItem: Identifiable, Codable, Sendable {
    var id: String { settingID }
    let settingID: String
    let target: SystemPreferenceTargetState
    let expectedValue: SystemPreferenceValue
    let desiredValue: SystemPreferenceValue
    let requiresRestart: Bool
    let riskLevel: SystemPreferenceRiskLevel
}

struct SystemPreferenceSkippedItem: Codable, Sendable {
    let settingID: String
    let reason: SystemPreferenceSkipReason
}

struct SystemPreferencesChangePlan: Identifiable, Codable, Sendable {
    let id: UUID
    let scanID: UUID
    let catalogRevision: String
    let createdAt: Date
    let expiresAt: Date
    let items: [SystemPreferenceChangePlanItem]
    let skippedItems: [SystemPreferenceSkippedItem]

    var requiresRestart: Bool { items.contains { $0.requiresRestart } }
    var highRiskItems: [SystemPreferenceChangePlanItem] {
        items.filter { $0.target == .optimized && $0.riskLevel == .high }
    }
}

enum SystemPreferenceChangeOutcome: String, Codable, Sendable {
    case changed
    case unchanged
    case failed
}

enum SystemPreferenceChangeFailureReason: String, Codable, Sendable {
    case settingChanged
    case permissionDenied
    case unsupported
    case verificationFailed
    case platformFailure
    case userCancelled
}

struct SystemPreferenceChangeItemResult: Identifiable, Codable, Sendable {
    var id: String { settingID }
    let settingID: String
    let outcome: SystemPreferenceChangeOutcome
    let verified: Bool
    let failureReason: SystemPreferenceChangeFailureReason?
}

struct SystemPreferencesChangeResult: Identifiable, Codable, Sendable {
    let id: UUID
    let planID: UUID
    let createdAt: Date
    let items: [SystemPreferenceChangeItemResult]

    var changedCount: Int { items.filter { $0.outcome == .changed }.count }
    var failedCount: Int { items.filter { $0.outcome == .failed }.count }
}

struct SystemPreferencesRecoveryItem: Codable, Equatable, Sendable {
    let settingID: String
    let originalValue: SystemPreferenceValue
    let optimizedValue: SystemPreferenceValue
}

struct SystemPreferencesRecoveryDocument: Codable, Sendable {
    static let currentSchemaVersion = 1
    let schemaVersion: Int
    let recoveryID: UUID
    let createdAt: Date
    var items: [SystemPreferencesRecoveryItem]
}
