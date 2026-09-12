import Foundation

/// Display copy lives here so UI files never hardcode user-visible strings.
enum L10n {
    private static var usesChinese: Bool {
        Locale.preferredLanguages.first?.hasPrefix("zh") == true
            || Locale.current.language.languageCode?.identifier == "zh"
    }

    private static func pick(zh: String, en: String) -> String {
        usesChinese ? zh : en
    }

    static var appName: String { AppIdentity.name }

    static var searchPlaceholder: String {
        pick(zh: "搜索剪贴板", en: "Search clipboard")
    }

    static var emptyTitle: String {
        pick(zh: "还没有剪贴记录", en: "No clipboard items yet")
    }

    static var noSearchResults: String {
        pick(zh: "没有匹配的剪贴内容", en: "No matching clips")
    }

    static var emptyHint: String {
        pick(
            zh: "复制后按 \(HotKeyConfig.displaySymbol) 唤起，点击方块即可粘贴到光标处",
            en: "Press \(HotKeyConfig.displaySymbol), then click a tile to paste at the caret"
        )
    }

    static var settingsTitle: String {
        pick(zh: "设置", en: "Settings")
    }

    static var retentionLabel: String {
        pick(zh: "保留条数", en: "Keep last")
    }

    static var retentionUnit: String {
        pick(zh: "条", en: "items")
    }

    static var expiryLabel: String {
        pick(zh: "过期时间", en: "Expire after")
    }

    static var expiryNever: String {
        pick(zh: "永久", en: "Never")
    }

    static func expiryDays(_ days: Int) -> String {
        pick(zh: "\(days) 天", en: days == 1 ? "1 day" : "\(days) days")
    }

    static var copied: String {
        pick(zh: "已复制", en: "Copied")
    }

    static var showPanel: String {
        pick(zh: "显示剪贴板", en: "Show Clipboard")
    }

    static var quit: String {
        pick(zh: "退出 iCopy", en: "Quit iCopy")
    }

    static var deleteItem: String {
        pick(zh: "删除", en: "Delete")
    }

    static var imageKind: String {
        pick(zh: "图片", en: "Image")
    }

    static var textKind: String {
        pick(zh: "文本", en: "Text")
    }

    static var justNow: String {
        pick(zh: "刚刚", en: "Just now")
    }

    static func minutesAgo(_ minutes: Int) -> String {
        pick(zh: "\(minutes) 分钟前", en: "\(minutes)m ago")
    }

    static func hoursAgo(_ hours: Int) -> String {
        pick(zh: "\(hours) 小时前", en: "\(hours)h ago")
    }

    static func daysAgo(_ days: Int) -> String {
        pick(zh: "\(days) 天前", en: "\(days)d ago")
    }

    static var customRetention: String {
        pick(zh: "自定义", en: "Custom")
    }

    static var statusItemDescription: String {
        pick(zh: "iCopy 剪贴板", en: "iCopy clipboard")
    }

    static var accessibilityTitle: String {
        pick(zh: "需要「辅助功能」权限", en: "Accessibility permission required")
    }

    static var accessibilityBody: String {
        pick(
            zh: "已将内容写入剪贴板。请在「系统设置 → 隐私与安全性 → 辅助功能」中打开 iCopy，然后完全退出并重新打开本应用，之后点击方块即可自动粘贴。",
            en: "The clip is already on the clipboard. Enable iCopy under System Settings → Privacy & Security → Accessibility, then quit and reopen this app so tile clicks can paste automatically."
        )
    }

    static var accessibilityOpenSettings: String {
        pick(zh: "打开设置", en: "Open Settings")
    }

    static var accessibilityLater: String {
        pick(zh: "稍后", en: "Later")
    }

    static func relativeTime(from date: Date, now: Date = Date()) -> String {
        let elapsed = now.timeIntervalSince(date)
        let minute: TimeInterval = 60
        let hour = minute * 60
        let day = hour * 24
        if elapsed < minute {
            return justNow
        }
        if elapsed < hour {
            return minutesAgo(max(1, Int(elapsed / minute)))
        }
        if elapsed < day {
            return hoursAgo(max(1, Int(elapsed / hour)))
        }
        return daysAgo(max(1, Int(elapsed / day)))
    }
}
