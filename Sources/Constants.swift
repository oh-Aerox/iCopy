import Foundation

/// Named product and storage identifiers so bundle paths stay stable across refactors.
enum AppIdentity {
    static let name = "iCopy"
    static let supportDirectoryName = "iCopy"
    static let historyFileName = "history.json"
    static let settingsFileName = "settings.json"
    static let imagesDirectoryName = "images"
}

/// Timing and layout values used by the docked clipboard panel.
enum PanelMetrics {
    static let height: CGFloat = 268
    static let horizontalInset: CGFloat = 24
    static let bottomInset: CGFloat = 16
    static let maxWidth: CGFloat = 1280
    static let cornerRadius: CGFloat = 18
    static let tileSize: CGFloat = 148
    static let tileSpacing: CGFloat = 12
    static let tileCornerRadius: CGFloat = 14
    static let chromeSpacing: CGFloat = 12
    static let panelPadding: CGFloat = 16
    static let chromeInnerPaddingX: CGFloat = 12
    static let chromeInnerPaddingY: CGFloat = 8
    static let hideAfterCopyDelay: TimeInterval = 0.35
    /// Wait for the previous app to take key focus before synthesizing ⌘V.
    static let restoreFocusBeforePasteDelay: TimeInterval = 0.12
    static let scrollAnimationDuration: TimeInterval = 0.15
    static let settingsWidth: CGFloat = 360
    static let customRetentionFieldWidth: CGFloat = 88
    static let escapeKeyCode: UInt16 = 53
    static let leftArrowKeyCode: UInt16 = 123
    static let rightArrowKeyCode: UInt16 = 124
    static let returnKeyCode: UInt16 = 36
    static let keypadEnterKeyCode: UInt16 = 76
    static let settingsPanelHeight: CGFloat = 210
    static let settingsControlInset: CGFloat = 16
    static let settingsRowHeight: CGFloat = 26
    static let chromeHeight: CGFloat = 32
    static let tileInnerInset: CGFloat = 12
    static let tileImageHeight: CGFloat = 86
    static let tileImageCornerRadius: CGFloat = 8
}

/// Clipboard capture and retention policy.
enum ClipboardLimits {
    /// Polling is used because AppKit has no clipboard-change notification.
    static let pollIntervalSeconds: TimeInterval = 0.45
    static let defaultRetentionCount = 50
    static let retentionPresets = [50, 100, 200]
    static let minRetentionCount = 10
    static let maxRetentionCount = 500
    static let defaultExpiryDays = 0
    static let expiryDayPresets = [0, 1, 7, 30]
    static let maxStoredImageEdge: CGFloat = 1024
    static let maxStoredImageBytes = 4_000_000
    static let textPreviewLimit = 96
}

enum HotKeyConfig {
    /// kVK_ANSI_V — Command+Shift+V is the conventional clipboard-history chord.
    static let carbonKeyCode: UInt32 = 9
    /// Carbon cmdKey | shiftKey, inlined so this file does not import Carbon.
    static let carbonModifiers: UInt32 = (1 << 8) | (1 << 9)
    /// Four-char code 'iCpy' so Carbon can distinguish this hotkey from others.
    static let carbonSignature: UInt32 = 0x69437079
    static let displaySymbol = "⌘⇧V"
}

enum Palette {
    static let shelfRed = 0.11
    static let shelfGreen = 0.10
    static let shelfBlue = 0.09
    static let paperRed = 0.965
    static let paperGreen = 0.937
    static let paperBlue = 0.894
    static let inkRed = 0.165
    static let inkGreen = 0.13
    static let inkBlue = 0.094
    static let accentRed = 0.77
    static let accentGreen = 0.36
    static let accentBlue = 0.15
    static let mutedRed = 0.45
    static let mutedGreen = 0.40
    static let mutedBlue = 0.36
}
