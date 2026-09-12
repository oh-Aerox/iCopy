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

        // Key synthesis is rejected unless the user has granted Accessibility to this process.
        if !AccessibilityTrust.ensurePrompted() {
            AppLog.error("paste.blocked_no_accessibility", [
                "app": target.bundleIdentifier ?? "",
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

enum AccessibilityTrust {
    static func ensurePrompted() -> Bool {
        if AXIsProcessTrusted() {
            return true
        }
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let trusted = AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary)
        AppLog.info("paste.accessibility_check", ["trusted": String(trusted)])
        return trusted
    }
}
