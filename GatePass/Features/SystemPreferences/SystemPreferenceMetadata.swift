import Foundation

enum SystemPreferenceRestartTarget: String, Codable, Sendable {
    case none
    case finder
    case dock
    case safari
    case textEdit
    case activityMonitor
    case mac
    case relatedApps

    func label(language: AppLanguage) -> String {
        switch self {
        case .none:
            return ""
        case .finder:
            return gatePassCopy("重启 Finder", "Relaunch Finder", language: language)
        case .dock:
            return gatePassCopy("重启 Dock", "Relaunch Dock", language: language)
        case .safari:
            return gatePassCopy("重启 Safari", "Relaunch Safari", language: language)
        case .textEdit:
            return gatePassCopy("重启 TextEdit", "Relaunch TextEdit", language: language)
        case .activityMonitor:
            return gatePassCopy("重启活动监视器", "Relaunch Activity Monitor", language: language)
        case .mac:
            return gatePassCopy("重启 Mac", "Restart Mac", language: language)
        case .relatedApps:
            return gatePassCopy("重启相关 App", "Relaunch affected apps", language: language)
        }
    }
}

struct SystemPreferenceLocalizedDescription: Sendable {
    let zh: String
    let en: String
}

enum SystemPreferenceMetadata {
    // macos-defaults.com currently marks these keys as "not sure".
    // Storage round-trip is verified by GatePass CI, but behavioral effect is not strong enough
    // for an automatic preset. They remain available only as explicit user choices.
    static let automaticPresetExcludedIDs: Set<String> = [
        "macos.finder.show-hard-drives-on-desktop",
        "macos.finder.show-external-drives-on-desktop",
        "macos.finder.show-removable-media-on-desktop",
        "macos.dock.show-only-open-apps",
        "macos.documents.save-locally",
        "macos.keyboard.disable-press-and-hold",
        "macos.dock.enable-spring-loading"
    ]

    static func isEligibleForAutomaticPreset(_ id: String) -> Bool {
        !automaticPresetExcludedIDs.contains(id)
    }

    static let descriptions: [String: SystemPreferenceLocalizedDescription] = [
        "macos.finder.show-file-extensions": .init(zh: "在 Finder 中始终显示文件扩展名，便于识别真实文件类型。", en: "Always show file extensions in Finder so the real file type is visible."),
        "macos.finder.show-path-bar": .init(zh: "在 Finder 窗口底部显示当前位置的完整路径，方便快速定位和跳转目录。", en: "Show the full current path at the bottom of Finder windows for faster navigation."),
        "macos.finder.show-status-bar": .init(zh: "在 Finder 底部显示项目数量、已选项目和可用磁盘空间。", en: "Show item counts, selections and available disk space in Finder."),
        "macos.finder.show-hidden-files": .init(zh: "在 Finder 中显示以点号开头等默认隐藏的文件和文件夹。", en: "Show files and folders that Finder normally hides, including dotfiles."),
        "macos.finder.show-posix-path": .init(zh: "在 Finder 窗口标题中显示当前目录的完整 POSIX 路径。", en: "Show the full POSIX path of the current folder in Finder window titles."),
        "macos.finder.disable-animations": .init(zh: "减少 Finder 打开窗口、切换视图等操作中的过渡动画。", en: "Reduce Finder transition animations when opening windows or changing views."),
        "macos.finder.keep-folders-on-top": .init(zh: "按名称排序时让文件夹始终排在文件之前。", en: "Keep folders above files when Finder items are sorted by name."),
        "macos.finder.search-current-folder": .init(zh: "使用 Finder 搜索时默认只搜索当前文件夹，而不是整台 Mac。", en: "Make Finder searches start in the current folder instead of the whole Mac."),
        "macos.finder.disable-extension-warning": .init(zh: "修改文件扩展名时不再弹出“确定要更改扩展名”确认框。", en: "Stop Finder from asking for confirmation every time a file extension is changed."),
        "macos.finder.show-hard-drives-on-desktop": .init(zh: "在桌面显示 Mac 内部硬盘图标。", en: "Show internal Mac disks on the desktop."),
        "macos.finder.show-external-drives-on-desktop": .init(zh: "连接外置硬盘或 SSD 时在桌面显示对应磁盘图标。", en: "Show external hard drives and SSDs on the desktop when connected."),
        "macos.finder.show-removable-media-on-desktop": .init(zh: "在桌面显示 U 盘、光盘等可移动介质。", en: "Show removable media such as USB drives and optical discs on the desktop."),
        "macos.finder.default-list-view": .init(zh: "让新的 Finder 窗口优先使用信息密度更高的列表视图。", en: "Prefer Finder's list view for new windows."),
        "macos.finder.enable-quit-menu": .init(zh: "在 Finder 菜单中显示“退出 Finder”，便于完全重启 Finder。", en: "Add Quit Finder to the Finder menu so Finder can be fully restarted."),
        "macos.finder.remove-old-trash-items": .init(zh: "允许 Finder 自动删除废纸篓中存放时间较长的项目；开启前请确认你接受自动清理。", en: "Allow Finder to automatically remove older Trash items; enable only if automatic cleanup is acceptable."),
        "macos.panels.expand-save": .init(zh: "保存文件时默认展开完整保存面板，直接显示目录和更多选项。", en: "Open save dialogs in expanded mode so folders and additional options are immediately visible."),
        "macos.panels.expand-print": .init(zh: "打印时默认展开完整打印面板，直接显示详细打印选项。", en: "Open print dialogs in expanded mode so detailed print options are immediately visible."),
        "macos.desktop.prevent-network-ds-store": .init(zh: "避免 Finder 在 SMB、NAS 等网络磁盘上创建 .DS_Store 元数据文件。", en: "Prevent Finder from creating .DS_Store metadata files on network volumes such as SMB shares and NAS devices."),
        "macos.desktop.prevent-usb-ds-store": .init(zh: "避免 Finder 在 USB 等外置磁盘上创建 .DS_Store 元数据文件。", en: "Prevent Finder from creating .DS_Store metadata files on USB and other removable volumes."),
        "macos.dock.auto-hide": .init(zh: "未使用 Dock 时自动隐藏，为应用窗口腾出更多屏幕空间。", en: "Automatically hide the Dock when it is not in use to free screen space."),
        "macos.dock.minimize-to-application": .init(zh: "最小化窗口时收纳到所属 App 的 Dock 图标，而不是生成独立缩略图。", en: "Minimize windows into their app's Dock icon instead of creating separate thumbnails."),
        "macos.dock.use-scale-effect": .init(zh: "将窗口最小化动画从“神奇效果”切换为更简洁的缩放效果。", en: "Use the simpler scale animation instead of the Genie effect when minimizing windows."),
        "macos.dock.hide-recent-apps": .init(zh: "关闭 Dock 右侧的最近使用 App 区域，减少干扰和使用痕迹展示。", en: "Hide recently used apps from the Dock to reduce clutter and exposed usage history."),
        "macos.dock.disable-launch-animation": .init(zh: "关闭从 Dock 启动 App 时的图标弹跳动画。", en: "Disable the bouncing Dock icon animation when launching apps."),
        "macos.dock.show-only-open-apps": .init(zh: "让 Dock 只显示当前正在运行的 App，隐藏未运行的固定项目。", en: "Show only currently running apps in the Dock and hide pinned apps that are not open."),
        "macos.dock.dim-hidden-apps": .init(zh: "在 Dock 中淡化已隐藏 App 的图标，便于分辨当前窗口状态。", en: "Dim Dock icons for hidden apps so their window state is easier to identify."),
        "macos.dock.remove-auto-hide-delay": .init(zh: "移除鼠标移到屏幕边缘后 Dock 出现前的等待时间。", en: "Remove the delay before an auto-hidden Dock appears when the pointer reaches the screen edge."),
        "macos.dock.enable-magnification": .init(zh: "开启 Dock 图标随指针靠近而放大的效果。", en: "Enable Dock icon magnification as the pointer moves across it."),
        "macos.screenshots.disable-shadow": .init(zh: "截取单个窗口时不在图片周围附加系统阴影。", en: "Remove the macOS drop shadow from individual window screenshots."),
        "macos.screenshots.use-png": .init(zh: "将系统截图格式固定为 PNG，保留无损画质和透明信息。", en: "Use PNG for screenshots to preserve lossless image quality and transparency."),
        "macos.screenshots.disable-thumbnail": .init(zh: "截图完成后不显示右下角悬浮缩略图，直接保存文件。", en: "Skip the floating screenshot thumbnail and save captures immediately."),
        "macos.keyboard.full-navigation": .init(zh: "允许使用 Tab 在按钮、复选框等更多界面控件之间移动焦点。", en: "Allow Tab to move keyboard focus through buttons, checkboxes and more interface controls."),
        "macos.keyboard.fast-key-repeat": .init(zh: "缩短按键重复间隔，让长按方向键或字符键时重复得更快。", en: "Shorten the key-repeat interval so held keys repeat more quickly."),
        "macos.keyboard.short-repeat-delay": .init(zh: "缩短长按按键后开始连续重复之前的等待时间。", en: "Reduce the delay before a held key begins repeating."),
        "macos.keyboard.disable-press-and-hold": .init(zh: "关闭字符长按重音候选菜单，使长按字母键直接连续输入。", en: "Disable the press-and-hold accent menu so holding a letter key repeats the character."),
        "macos.keyboard.use-standard-function-keys": .init(zh: "默认把 F1–F12 当作标准功能键；使用亮度、音量等媒体功能时需配合 Fn。", en: "Treat F1–F12 as standard function keys by default; use Fn for brightness, volume and other media actions."),
        "macos.documents.save-locally": .init(zh: "新文档保存时默认优先本地位置，而不是 iCloud。", en: "Prefer local storage rather than iCloud as the default location for new documents."),
        "macos.text.disable-auto-correct": .init(zh: "关闭系统级自动拼写纠正，避免输入内容被自动改写。", en: "Disable system-wide automatic spelling correction so typed text is not changed automatically."),
        "macos.text.disable-smart-quotes": .init(zh: "关闭直引号自动替换为弯引号的智能引号功能。", en: "Disable automatic replacement of straight quotes with typographic smart quotes."),
        "macos.text.disable-smart-dashes": .init(zh: "关闭连续连字符自动替换为长短破折号的功能。", en: "Disable automatic replacement of hyphens with typographic smart dashes."),
        "macos.text.disable-auto-capitalization": .init(zh: "关闭系统自动将句首字母转换为大写。", en: "Disable automatic capitalization at the beginning of sentences."),
        "macos.text.disable-period-substitution": .init(zh: "关闭连续输入两个空格时自动插入句号的功能。", en: "Disable automatic period insertion when pressing the space bar twice."),
        "macos.finder.warn-before-empty-trash": .init(zh: "清空废纸篓前保留确认提示，降低误删文件的风险。", en: "Keep the confirmation prompt before emptying the Trash to reduce accidental deletion."),
        "macos.dock.enable-spring-loading": .init(zh: "拖拽文件停留在 Dock App 图标上时允许自动展开或打开目标。", en: "Enable spring-loaded behavior when dragging files over supported Dock app icons."),
        "macos.dock.scroll-to-expose": .init(zh: "在 Dock App 图标上滚动时触发窗口展示，快速查看该 App 的窗口。", en: "Use scrolling over a Dock app icon to expose that app's windows."),
        "macos.dock.fast-auto-hide-animation": .init(zh: "缩短 Dock 自动隐藏和显示过程的动画时间。", en: "Shorten the animation used when the Dock automatically hides or appears."),
        "macos.dock.lock-contents": .init(zh: "锁定 Dock 中的项目布局，禁止通过拖拽添加、移除或重新排列 App 和文件夹；关闭后恢复正常编辑。", en: "Lock the Dock item layout so apps and folders cannot be added, removed or rearranged by dragging; turn it off to restore normal editing."),
        "macos.dock.lock-size": .init(zh: "锁定 Dock 当前大小，禁止通过拖动 Dock 分隔线调整尺寸；关闭后恢复正常缩放。", en: "Lock the current Dock size so it cannot be resized by dragging the Dock divider; turn it off to restore normal resizing."),
        "macos.text.disable-text-completion": .init(zh: "关闭系统文本补全候选，减少输入过程中自动补全文本。", en: "Disable system text-completion suggestions while typing."),
        "macos.text.disable-inline-predictions": .init(zh: "关闭输入框中的行内预测文字，避免灰色预测内容自动出现。", en: "Disable inline predictive text so gray predicted completions do not appear while typing."),
        "macos.finder.open-folders-in-tabs": .init(zh: "在 Finder 中使用 Command 双击或相关菜单打开文件夹时，优先在新标签页而不是新窗口中打开。", en: "Prefer opening Finder folders in a new tab rather than a new window for supported commands."),
        "macos.finder.auto-size-columns": .init(zh: "在 Finder 分栏视图中按可见文件名自动调整每一栏的宽度。", en: "Automatically size Finder columns to fit the visible filenames in column view."),
        "macos.desktop.hide-all-icons": .init(zh: "隐藏桌面上的全部 Finder 图标，让桌面保持干净；文件本身不会被删除。", en: "Hide all Finder icons on the desktop without deleting any files."),
        "macos.mouse.disable-acceleration": .init(zh: "关闭 macOS 鼠标指针加速，使相同物理移动距离更接近固定的指针移动量；更适合游戏或依赖肌肉记忆的操作。", en: "Disable macOS mouse acceleration for more linear pointer movement, useful for gaming or muscle-memory workflows."),
        "macos.keyboard.hide-language-indicator": .init(zh: "切换多个输入法时不显示屏幕中央的语言/输入源提示。", en: "Hide the on-screen language indicator when switching between configured input sources."),
        "macos.screenshots.hide-date": .init(zh: "系统截图文件名不再附带日期和时间；连续截图仍会由系统自动避免重名。", en: "Remove the date and time from screenshot filenames while letting macOS avoid duplicate names."),
        "macos.messages.show-subject-field": .init(zh: "在“信息”App 的消息输入区显示主题栏，可为 iMessage 或短信添加主题。", en: "Show a subject field above the message composer in Messages."),
        "macos.music.disable-track-notifications": .init(zh: "关闭“音乐”App 在切换到新歌曲时显示的播放通知。", en: "Disable Music notifications that appear when playback moves to a new track."),
        "macos.terminal.focus-follows-mouse": .init(zh: "鼠标移到另一个“终端”窗口上时自动将键盘焦点切换到该窗口，仅影响 Terminal 窗口之间。", en: "Move keyboard focus between Terminal windows by hovering the pointer over them."),
        "macos.menubar.flash-time-separators": .init(zh: "让菜单栏时钟中的时间分隔符每秒闪烁一次。", en: "Flash the menu bar clock's time separator once per second."),
    ]

    static func description(for id: String, fallbackZH: String, fallbackEN: String) -> SystemPreferenceLocalizedDescription {
        descriptions[id] ?? .init(zh: fallbackZH, en: fallbackEN)
    }

    static func minimumMacOSMajorVersion(for id: String) -> Int {
        switch id {
        case "macos.finder.auto-size-columns":
            return 26
        case "macos.text.disable-text-completion",
             "macos.text.disable-inline-predictions",
             "macos.finder.open-folders-in-tabs",
             "macos.mouse.disable-acceleration",
             "macos.keyboard.hide-language-indicator",
             "macos.messages.show-subject-field":
            return 14
        default:
            return 13
        }
    }

    static func restartTarget(for definition: SystemPreferenceDefinition) -> SystemPreferenceRestartTarget {
        guard definition.requiresRestart else { return .none }
        if definition.id == "macos.mouse.disable-acceleration" { return .mac }
        switch definition.component {
        case .finder, .desktop:
            return .finder
        case .dock, .missionControl:
            return .dock
        case .safari:
            return .safari
        case .textEdit:
            return .textEdit
        case .activityMonitor:
            return .activityMonitor
        default:
            return .relatedApps
        }
    }
}

extension SystemPreferenceDefinition {
    func detailedSummary(language: AppLanguage) -> String {
        let copy = SystemPreferenceMetadata.description(for: id, fallbackZH: summaryZH, fallbackEN: summaryEN)
        return gatePassCopy(copy.zh, copy.en, language: language)
    }

    var restartTarget: SystemPreferenceRestartTarget {
        SystemPreferenceMetadata.restartTarget(for: self)
    }

    var minimumMacOSMajorVersion: Int {
        SystemPreferenceMetadata.minimumMacOSMajorVersion(for: id)
    }

    func isSupported(on version: OperatingSystemVersion) -> Bool {
        version.majorVersion >= minimumMacOSMajorVersion
    }
}

extension SystemPreferenceDiagnostic {
    func title(language: AppLanguage) -> String {
        switch self {
        case .unsupported:
            return gatePassCopy("当前系统不支持", "Unsupported on this macOS", language: language)
        case .accessDenied:
            return gatePassCopy("权限受限", "Access restricted", language: language)
        case .stateUnavailable:
            return gatePassCopy("读取失败", "State unavailable", language: language)
        }
    }

    func detail(for definition: SystemPreferenceDefinition, language: AppLanguage) -> String {
        switch self {
        case .unsupported:
            return gatePassCopy(
                "此偏好至少需要 macOS \(definition.minimumMacOSMajorVersion)，当前系统不会尝试读取或修改。",
                "This preference requires macOS \(definition.minimumMacOSMajorVersion) or later; GatePass will not read or modify it on this system.",
                language: language
            )
        case .accessDenied:
            return gatePassCopy(
                "macOS 拒绝访问此偏好。GatePass 不会尝试提权或绕过系统限制。",
                "macOS denied access to this preference. GatePass will not elevate privileges or bypass the restriction.",
                language: language
            )
        case .stateUnavailable:
            return gatePassCopy(
                "未能可靠读取当前值。为避免覆盖未知状态，此项已停止修改。",
                "The current value could not be read reliably. This item is disabled to avoid overwriting an unknown state.",
                language: language
            )
        }
    }
}

extension SystemPreferenceChangeFailureReason {
    func title(language: AppLanguage) -> String {
        switch self {
        case .settingChanged:
            return gatePassCopy("状态已变化", "State changed", language: language)
        case .permissionDenied:
            return gatePassCopy("权限不足", "Permission denied", language: language)
        case .unsupported:
            return gatePassCopy("当前系统不支持", "Unsupported", language: language)
        case .verificationFailed:
            return gatePassCopy("写入后验证失败", "Verification failed", language: language)
        case .platformFailure:
            return gatePassCopy("系统操作失败", "System operation failed", language: language)
        case .userCancelled:
            return gatePassCopy("已取消", "Cancelled", language: language)
        }
    }
}
