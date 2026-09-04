import Foundation

enum MacSystemPreferencesCatalog {
    static let revision = "gatepass-macos-system-preferences-v3"
    static let all: [SystemPreferenceDefinition] = [
        d("macos.finder.show-file-extensions", "显示所有文件扩展名", "Show all file extensions", .productivity, .oneClick, .standard, "NSGlobalDomain", "AppleShowAllExtensions", .boolean, .bool(false), .bool(true), nil, true),
        d("macos.finder.show-path-bar", "显示 Finder 路径栏", "Show Finder path bar", .productivity, .oneClick, .standard, "com.apple.finder", "ShowPathbar", .boolean, .bool(false), .bool(true), nil, true),
        d("macos.finder.show-status-bar", "显示 Finder 状态栏", "Show Finder status bar", .productivity, .oneClick, .standard, "com.apple.finder", "ShowStatusBar", .boolean, .bool(false), .bool(true), nil, true),
        d("macos.finder.show-hidden-files", "显示隐藏文件", "Show hidden files", .productivity, .oneClick, .standard, "com.apple.finder", "AppleShowAllFiles", .boolean, .bool(false), .bool(true), nil, false),
        d("macos.finder.show-posix-path", "标题栏显示完整路径", "Show full path in Finder title", .productivity, .oneClick, .standard, "com.apple.finder", "_FXShowPosixPathInTitle", .boolean, .bool(false), .bool(true), nil, true),
        d("macos.finder.disable-animations", "关闭 Finder 动画", "Disable Finder animations", .performance, .custom, .standard, "com.apple.finder", "DisableAllAnimations", .boolean, .bool(false), .bool(true), nil, true),
        d("macos.finder.keep-folders-on-top", "文件夹置顶", "Keep folders on top", .productivity, .oneClick, .standard, "com.apple.finder", "_FXSortFoldersFirst", .boolean, .bool(false), .bool(true), nil, true),
        d("macos.finder.search-current-folder", "默认搜索当前文件夹", "Search current folder by default", .productivity, .oneClick, .standard, "com.apple.finder", "FXDefaultSearchScope", .text, .text("SCev"), .text("SCcf"), nil, true),
        d("macos.finder.disable-extension-warning", "关闭扩展名修改警告", "Disable extension change warning", .productivity, .custom, .standard, "com.apple.finder", "FXEnableExtensionChangeWarning", .boolean, .bool(true), .bool(false), nil, true),
        d("macos.finder.show-hard-drives-on-desktop", "桌面显示硬盘", "Show hard drives on desktop", .productivity, .custom, .standard, "com.apple.finder", "ShowHardDrivesOnDesktop", .boolean, .bool(false), .bool(true), nil, true),
        d("macos.finder.show-external-drives-on-desktop", "桌面显示外置磁盘", "Show external drives on desktop", .productivity, .custom, .standard, "com.apple.finder", "ShowExternalHardDrivesOnDesktop", .boolean, .bool(false), .bool(true), nil, true),
        d("macos.finder.show-removable-media-on-desktop", "桌面显示可移动介质", "Show removable media on desktop", .productivity, .custom, .standard, "com.apple.finder", "ShowRemovableMediaOnDesktop", .boolean, .bool(false), .bool(true), nil, true),
        d("macos.finder.default-list-view", "Finder 默认列表视图", "Default Finder list view", .productivity, .custom, .standard, "com.apple.finder", "FXPreferredViewStyle", .text, .missing, .text("Nlsv"), nil, true),
        d("macos.finder.open-folders-in-tabs", "文件夹优先在新标签页打开", "Open folders in new tabs", .productivity, .custom, .standard, "com.apple.finder", "FinderSpawnTab", .boolean, .bool(true), .bool(true), .bool(false), false),
        d("macos.finder.auto-size-columns", "自动调整 Finder 分栏宽度", "Auto-size Finder columns", .productivity, .custom, .standard, "com.apple.finder", "_FXEnableColumnAutoSizing", .boolean, .bool(false), .bool(true), .bool(false), false),
        d("macos.finder.enable-quit-menu", "启用退出 Finder", "Enable Quit Finder", .productivity, .custom, .standard, "com.apple.finder", "QuitMenuItem", .boolean, .missing, .bool(true), nil, true),
        d("macos.finder.remove-old-trash-items", "自动删除旧废纸篓项目", "Remove old Trash items", .storage, .custom, .caution, "com.apple.finder", "FXRemoveOldTrashItems", .boolean, .missing, .bool(true), nil, true),
        d("macos.panels.expand-save", "默认展开保存面板", "Expand save panels", .productivity, .oneClick, .standard, "NSGlobalDomain", "NSNavPanelExpandedStateForSaveMode", .boolean, .bool(false), .bool(true), nil, false),
        d("macos.panels.expand-print", "默认展开打印面板", "Expand print panels", .productivity, .oneClick, .standard, "NSGlobalDomain", "PMPrintingExpandedStateForPrint", .boolean, .bool(false), .bool(true), nil, false),
        d("macos.desktop.prevent-network-ds-store", "网络磁盘不创建 .DS_Store", "Prevent network .DS_Store", .storage, .oneClick, .standard, "com.apple.desktopservices", "DSDontWriteNetworkStores", .boolean, .bool(false), .bool(true), nil, true),
        d("macos.desktop.prevent-usb-ds-store", "USB 磁盘不创建 .DS_Store", "Prevent USB .DS_Store", .storage, .oneClick, .standard, "com.apple.desktopservices", "DSDontWriteUSBStores", .boolean, .bool(false), .bool(true), nil, true),
        d("macos.desktop.hide-all-icons", "隐藏桌面所有图标", "Hide all desktop icons", .appearance, .custom, .standard, "com.apple.finder", "CreateDesktop", .boolean, .bool(true), .bool(false), .bool(true), false),
        d("macos.dock.auto-hide", "自动隐藏 Dock", "Auto-hide Dock", .appearance, .custom, .standard, "com.apple.dock", "autohide", .boolean, .bool(false), .bool(true), nil, true),
        d("macos.dock.minimize-to-application", "窗口最小化到 App 图标", "Minimize windows into app icon", .appearance, .custom, .standard, "com.apple.dock", "minimize-to-application", .boolean, .bool(false), .bool(true), nil, true),
        d("macos.dock.use-scale-effect", "使用缩放最小化效果", "Use scale minimize effect", .performance, .oneClick, .standard, "com.apple.dock", "mineffect", .text, .text("genie"), .text("scale"), nil, true),
        d("macos.dock.hide-recent-apps", "隐藏 Dock 最近 App", "Hide recent Dock apps", .privacy, .oneClick, .standard, "com.apple.dock", "show-recents", .boolean, .bool(true), .bool(false), nil, true),
        d("macos.dock.disable-launch-animation", "关闭 App 启动动画", "Disable app launch animation", .performance, .custom, .standard, "com.apple.dock", "launchanim", .boolean, .bool(true), .bool(false), nil, true),
        d("macos.dock.show-only-open-apps", "Dock 只显示运行中的 App", "Show only open apps in Dock", .appearance, .custom, .standard, "com.apple.dock", "static-only", .boolean, .bool(false), .bool(true), nil, true),
        d("macos.dock.dim-hidden-apps", "淡化已隐藏 App", "Dim hidden apps", .productivity, .custom, .standard, "com.apple.dock", "showhidden", .boolean, .bool(false), .bool(true), nil, true),
        d("macos.dock.remove-auto-hide-delay", "移除 Dock 显示延迟", "Remove Dock auto-hide delay", .performance, .custom, .standard, "com.apple.dock", "autohide-delay", .floatingPoint, .double(0.2), .double(0), nil, true),
        d("macos.dock.enable-magnification", "启用 Dock 放大", "Enable Dock magnification", .appearance, .custom, .standard, "com.apple.dock", "magnification", .boolean, .missing, .bool(true), nil, true),
        d("macos.screenshots.disable-shadow", "截图不带窗口阴影", "Disable screenshot shadows", .appearance, .oneClick, .standard, "com.apple.screencapture", "disable-shadow", .boolean, .bool(false), .bool(true), nil, false),
        d("macos.screenshots.use-png", "截图使用 PNG", "Use PNG screenshots", .appearance, .custom, .standard, "com.apple.screencapture", "type", .text, .text("png"), .text("png"), .text("jpg"), false),
        d("macos.screenshots.disable-thumbnail", "关闭截图悬浮缩略图", "Disable screenshot thumbnail", .productivity, .oneClick, .standard, "com.apple.screencapture", "show-thumbnail", .boolean, .bool(true), .bool(false), nil, false),
        d("macos.screenshots.hide-date", "截图文件名不含日期", "Hide date in screenshot filenames", .appearance, .custom, .standard, "com.apple.screencapture", "include-date", .boolean, .bool(true), .bool(false), .bool(true), false),
        d("macos.keyboard.full-navigation", "启用完整键盘导航", "Enable full keyboard navigation", .productivity, .custom, .standard, "NSGlobalDomain", "AppleKeyboardUIMode", .integer, .int(0), .int(2), nil, false),
        d("macos.keyboard.fast-key-repeat", "加快按键重复", "Faster key repeat", .performance, .custom, .standard, "NSGlobalDomain", "KeyRepeat", .integer, .missing, .int(2), nil, false),
        d("macos.keyboard.short-repeat-delay", "缩短按键重复延迟", "Shorter key repeat delay", .performance, .custom, .standard, "NSGlobalDomain", "InitialKeyRepeat", .integer, .missing, .int(15), nil, false),
        d("macos.keyboard.disable-press-and-hold", "关闭长按候选", "Disable press-and-hold accents", .performance, .custom, .standard, "NSGlobalDomain", "ApplePressAndHoldEnabled", .boolean, .bool(true), .bool(false), nil, false),
        d("macos.keyboard.use-standard-function-keys", "F1–F12 作为标准功能键", "Use standard function keys", .productivity, .custom, .standard, "NSGlobalDomain", "com.apple.keyboard.fnState", .boolean, .missing, .bool(true), nil, false),
        d("macos.keyboard.hide-language-indicator", "隐藏输入法切换提示", "Hide input source indicator", .appearance, .custom, .standard, "kCFPreferencesAnyApplication", "TSMLanguageIndicatorEnabled", .boolean, .bool(true), .bool(false), .bool(true), false),
        d("macos.mouse.disable-acceleration", "关闭鼠标指针加速", "Disable mouse pointer acceleration", .performance, .custom, .caution, "NSGlobalDomain", "com.apple.mouse.linear", .boolean, .bool(false), .bool(true), .bool(false), true),
        d("macos.documents.save-locally", "新文档默认保存到本地", "Save new documents locally", .storage, .custom, .standard, "NSGlobalDomain", "NSDocumentSaveNewDocumentsToCloud", .boolean, .bool(true), .bool(false), nil, false),
        d("macos.text.disable-auto-correct", "关闭自动纠正", "Disable auto-correct", .productivity, .custom, .standard, "NSGlobalDomain", "NSAutomaticSpellingCorrectionEnabled", .boolean, .bool(true), .bool(false), nil, false),
        d("macos.text.disable-smart-quotes", "关闭智能引号", "Disable smart quotes", .productivity, .custom, .standard, "NSGlobalDomain", "NSAutomaticQuoteSubstitutionEnabled", .boolean, .bool(true), .bool(false), nil, false),
        d("macos.text.disable-smart-dashes", "关闭智能破折号", "Disable smart dashes", .productivity, .custom, .standard, "NSGlobalDomain", "NSAutomaticDashSubstitutionEnabled", .boolean, .bool(true), .bool(false), nil, false),
        d("macos.text.disable-auto-capitalization", "关闭自动大写", "Disable auto-capitalization", .productivity, .custom, .standard, "NSGlobalDomain", "NSAutomaticCapitalizationEnabled", .boolean, .bool(true), .bool(false), nil, false),
        d("macos.text.disable-period-substitution", "关闭双空格句号", "Disable period substitution", .productivity, .custom, .standard, "NSGlobalDomain", "NSAutomaticPeriodSubstitutionEnabled", .boolean, .bool(true), .bool(false), nil, false),
        d("macos.finder.warn-before-empty-trash", "清空废纸篓前警告", "Warn before emptying Trash", .productivity, .custom, .standard, "com.apple.finder", "WarnOnEmptyTrash", .boolean, .bool(true), .bool(true), .bool(false), false),
        d("macos.dock.enable-spring-loading", "启用 Dock 拖放弹簧加载", "Enable Dock spring loading", .productivity, .custom, .standard, "com.apple.dock", "enable-spring-load-actions-on-all-items", .boolean, .missing, .bool(true), nil, true),
        d("macos.dock.scroll-to-expose", "Dock 滚动显示窗口", "Scroll Dock to expose windows", .productivity, .custom, .standard, "com.apple.dock", "scroll-to-open", .boolean, .missing, .bool(true), nil, true),
        d("macos.dock.fast-auto-hide-animation", "加快 Dock 自动隐藏动画", "Faster Dock auto-hide animation", .performance, .custom, .standard, "com.apple.dock", "autohide-time-modifier", .floatingPoint, .double(0.5), .double(0), nil, true),
        d("macos.dock.lock-contents", "锁定 Dock 内容", "Lock Dock contents", .productivity, .custom, .caution, "com.apple.dock", "contents-immutable", .boolean, .missing, .bool(true), .bool(false), true),
        d("macos.dock.lock-size", "锁定 Dock 大小", "Lock Dock size", .appearance, .custom, .caution, "com.apple.dock", "size-immutable", .boolean, .missing, .bool(true), .bool(false), true),
        d("macos.text.disable-text-completion", "关闭文本补全", "Disable text completion", .productivity, .custom, .standard, "NSGlobalDomain", "NSAutomaticTextCompletionEnabled", .boolean, .bool(true), .bool(false), nil, false),
        d("macos.text.disable-inline-predictions", "关闭行内预测", "Disable inline predictions", .privacy, .custom, .standard, "NSGlobalDomain", "NSAutomaticInlinePredictionEnabled", .boolean, .bool(true), .bool(false), nil, false),
        d("macos.messages.show-subject-field", "信息显示主题栏", "Show Messages subject field", .productivity, .custom, .standard, "com.apple.MobileSMS", "MMSShowSubject", .boolean, .bool(false), .bool(true), .bool(false), true),
        d("macos.music.disable-track-notifications", "关闭音乐切歌通知", "Disable Music track notifications", .productivity, .custom, .standard, "com.apple.Music", "userWantsPlaybackNotifications", .boolean, .bool(true), .bool(false), .bool(true), true),
        d("macos.terminal.focus-follows-mouse", "终端窗口焦点跟随鼠标", "Terminal focus follows mouse", .productivity, .custom, .standard, "com.apple.Terminal", "FocusFollowsMouse", .boolean, .bool(false), .bool(true), .bool(false), true),
        d("macos.menubar.flash-time-separators", "菜单栏时间分隔符闪烁", "Flash menu bar time separators", .appearance, .custom, .standard, "com.apple.menuextra.clock", "FlashDateSeparators", .boolean, .bool(false), .bool(true), .bool(false), false),
    ]

    static let byID: [String: SystemPreferenceDefinition] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    private static func d(
        _ id: String, _ titleZH: String, _ titleEN: String,
        _ category: SystemPreferenceCategory, _ selectionKind: SystemPreferenceSelectionKind,
        _ riskLevel: SystemPreferenceRiskLevel, _ domain: String, _ key: String,
        _ valueType: SystemPreferenceValueType, _ defaultValue: SystemPreferenceValue,
        _ recommendedValue: SystemPreferenceValue, _ disabledValue: SystemPreferenceValue?,
        _ requiresRestart: Bool
    ) -> SystemPreferenceDefinition {
        SystemPreferenceDefinition(
            id: id,
            titleZH: titleZH,
            titleEN: titleEN,
            summaryZH: descriptionZH(for: category),
            summaryEN: descriptionEN(for: category),
            category: category,
            selectionKind: selectionKind,
            riskLevel: riskLevel,
            domain: domain,
            key: key,
            valueType: valueType,
            defaultValue: defaultValue,
            recommendedValue: recommendedValue,
            disabledValue: disabledValue,
            requiresRestart: requiresRestart
        )
    }

    private static func descriptionZH(for category: SystemPreferenceCategory) -> String {
        switch category {
        case .performance: return "调整 macOS 行为以提升响应速度。"
        case .productivity: return "调整 macOS 日常使用偏好以提高效率。"
        case .privacy: return "调整与隐私、安全和数据暴露相关的系统偏好。"
        case .storage: return "调整文件与存储相关的系统偏好。"
        case .appearance: return "调整窗口、Dock 或界面显示行为。"
        }
    }

    private static func descriptionEN(for category: SystemPreferenceCategory) -> String {
        switch category {
        case .performance: return "Tune macOS behavior for faster response."
        case .productivity: return "Tune everyday macOS preferences for productivity."
        case .privacy: return "Tune preferences related to privacy, security and data exposure."
        case .storage: return "Tune file and storage related preferences."
        case .appearance: return "Tune window, Dock and interface behavior."
        }
    }
}
