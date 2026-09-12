import ApplicationServices
import AppKit

/// Restores the app that had the caret before the shelf opened, then synthesizes ⌘V.
enum TargetAppPaste {
    static func rememberFrontmostApp() -> NSRunningApplication? {
        guard let front = NSWorkspace.shared.frontmostApplication else { return nil }
        if front.processIdentifier == ProcessInfo.processInfo.processIdentifier {
            return nil
        }
        AppLog.info("paste.target_saved", [
            "app": front.bundleIdentifier ?? front.localizedName ?? "",
            "pid": String(front.processIdentifier),
        ])
        return front
    }

    static func paste(into target: NSRunningApplication?) {
        guard let target, !target.isTerminated else {
            AppLog.error("paste.missing_target")
            return
        }
        guard target.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            AppLog.error("paste.target_is_self")
            return
        }

        // Clipboard is already restored by the caller; Accessibility is only needed for ⌘V.
        if !AccessibilityTrust.canSynthesizeKeys() {
            AppLog.error("paste.blocked_no_accessibility", [
                "app": target.bundleIdentifier ?? "",
                "prompted": String(AccessibilityTrust.didPromptThisLaunch),
            ])
            return
        }

        // Sonoma+ ignores activateIgnoringOtherApps; transfer key focus from our accessory process.
        let handedOff = target.activate(from: NSRunningApplication.current)
        AppLog.info("paste.activate", [
            "ok": String(handedOff),
            "app": target.bundleIdentifier ?? "",
        ])
        let pid = target.processIdentifier
        DispatchQueue.main.asyncAfter(deadline: .now() + PanelMetrics.restoreFocusBeforePasteDelay) {
            sendCommandV(to: pid)
        }
    }

    private static func sendCommandV(to pid: pid_t) {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            AppLog.error("paste.event_source_failed")
            return
        }
        let key = CGKeyCode(HotKeyConfig.carbonKeyCode)
        guard
            let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true),
            let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        else {
            AppLog.error("paste.event_create_failed")
            return
        }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.postToPid(pid)
        up.postToPid(pid)
        AppLog.info("paste.sent", ["pid": String(pid)])
    }
}

/// Accessibility grants stick to the signed binary. Re-prompting with prompt:true on every paste
/// reopens the system sheet whenever the current process is still untrusted (common until relaunch).
enum AccessibilityTrust {
    private(set) static var didPromptThisLaunch = false
    private static var didShowGuideAlert = false

    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Returns whether key synthesis is allowed. Shows the OS prompt at most once per launch.
    static func canSynthesizeKeys() -> Bool {
        if isTrusted {
            return true
        }

        if !didPromptThisLaunch {
            didPromptThisLaunch = true
            let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            // prompt:true only on the first denial — later pastes must not call this again.
            let trustedNow = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
            AppLog.info("paste.accessibility_prompt", ["trusted": String(trustedNow)])
            if trustedNow {
                return true
            }
            openAccessibilitySettings()
            showEnableGuideIfNeeded()
            return false
        }

        // User may have toggled the switch without quitting; re-check quietly, never re-prompt.
        let trusted = isTrusted
        AppLog.info("paste.accessibility_recheck", ["trusted": String(trusted)])
        if !trusted {
            showEnableGuideIfNeeded()
        }
        return trusted
    }

    private static func openAccessibilitySettings() {
        for raw in AccessibilitySettingsURL.candidates {
            if let url = URL(string: raw), NSWorkspace.shared.open(url) {
                AppLog.info("paste.accessibility_settings_opened", ["url": raw])
                return
            }
        }
        AppLog.error("paste.accessibility_settings_failed")
    }

    private static func showEnableGuideIfNeeded() {
        guard !didShowGuideAlert else { return }
        didShowGuideAlert = true
        let alert = NSAlert()
        alert.messageText = L10n.accessibilityTitle
        alert.informativeText = L10n.accessibilityBody
        alert.alertStyle = .informational
        alert.addButton(withTitle: L10n.accessibilityOpenSettings)
        alert.addButton(withTitle: L10n.accessibilityLater)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }
}

enum AccessibilitySettingsURL {
    /// Prefer newer Settings deep links; fall back to the legacy Security pane.
    static let candidates = [
        "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
        "x-apple.systempreferences:com.apple.Settings.PrivacySecurity.extension?Privacy_Accessibility",
    ]
}
