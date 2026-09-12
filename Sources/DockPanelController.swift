import AppKit

/// A borderless panel that sits on the current screen’s bottom edge, like a shelf under the front window.
final class DockPanelController {
    private let store: HistoryStore
    private let onCopy: (ClipboardItem) -> Void
    private var panel: DockPanel?
    private var content: DockContentView?
    private var localKeyMonitor: Any?
    private var globalClickMonitor: Any?
    private var localClickMonitor: Any?
    private var resignObserver: NSObjectProtocol?
    private var pasteTarget: NSRunningApplication?

    init(store: HistoryStore, onCopy: @escaping (ClipboardItem) -> Void) {
        self.store = store
        self.onCopy = onCopy
    }

    var isVisible: Bool {
        panel?.isVisible == true
    }

    func toggle() {
        if isVisible {
            hide(reason: DismissReason.toggle)
        } else {
            show()
        }
    }

    func show() {
        // Capture the caret owner before we steal activation for the shelf.
        if let target = TargetAppPaste.rememberFrontmostApp() {
            pasteTarget = target
        }
        let panel = existingOrCreate()
        position(panel)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        content?.focusSearch()
        startDismissTracking()
        AppLog.info("panel.shown", ["items": String(store.items.count)])
    }

    func hide(reason: String = DismissReason.manual) {
        guard isVisible else {
            stopDismissTracking()
            return
        }
        stopDismissTracking()
        content?.dismissOverlays()
        panel?.orderOut(nil)
        AppLog.info("panel.hidden", ["reason": reason])
    }

    private func existingOrCreate() -> DockPanel {
        if let panel {
            return panel
        }

        let panel = DockPanel(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: PanelMetrics.height),
            // Avoid .nonactivatingPanel: those windows click through, so a tile click
            // would hit the app behind, hide the shelf, and never paste.
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        // We hide ourselves on resign/outside-click so monitors and the settings popover stay in sync.
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true

        let content = DockContentView(
            store: store,
            onCopy: { [weak self] item in
                guard let self else { return }
                self.onCopy(item)
                self.hide(reason: DismissReason.copied)
                TargetAppPaste.paste(into: self.pasteTarget)
            },
            onHide: { [weak self] in self?.hide(reason: DismissReason.manual) }
        )
        panel.contentView = content
        self.content = content

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if event.keyCode == PanelMetrics.escapeKeyCode {
                self.hide(reason: DismissReason.escape)
                return nil
            }
            if event.keyCode == PanelMetrics.leftArrowKeyCode {
                self.content?.moveSelection(-1)
                return nil
            }
            if event.keyCode == PanelMetrics.rightArrowKeyCode {
                self.content?.moveSelection(1)
                return nil
            }
            if event.keyCode == PanelMetrics.returnKeyCode || event.keyCode == PanelMetrics.keypadEnterKeyCode {
                self.content?.copySelected()
                return nil
            }
            return event
        }

        self.panel = panel
        return panel
    }

    private func position(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }

        let width = min(visible.width - PanelMetrics.horizontalInset * 2, PanelMetrics.maxWidth)
        let x = visible.midX - width / 2
        let y = visible.minY + PanelMetrics.bottomInset
        panel.setFrame(
            NSRect(x: x, y: y, width: width, height: PanelMetrics.height),
            display: true
        )
    }

    /// Clicks that leave the shelf (other apps, desktop, menu bar) should tuck it away.
    private func startDismissTracking() {
        stopDismissTracking()

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hide(reason: DismissReason.outsideClick)
        }

        localClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, self.isVisible else { return event }
            // Use the event window, not mouse-point math — tiles live inside the panel
            // and a false "outside" here would hide the shelf before the card receives the click.
            if !self.eventIsOnShelf(event) {
                self.hide(reason: DismissReason.outsideClick)
            }
            return event
        }

        resignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.hide(reason: DismissReason.appResigned)
        }
    }

    private func stopDismissTracking() {
        if let globalClickMonitor {
            NSEvent.removeMonitor(globalClickMonitor)
            self.globalClickMonitor = nil
        }
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
            self.localClickMonitor = nil
        }
        if let resignObserver {
            NotificationCenter.default.removeObserver(resignObserver)
            self.resignObserver = nil
        }
    }

    private func eventIsOnShelf(_ event: NSEvent) -> Bool {
        guard let window = event.window else { return false }
        if window === panel {
            return true
        }
        // Settings lives in a transient popover window; treat it as part of the shelf.
        return window.level != .statusBar
    }
}

enum DismissReason {
    static let toggle = "toggle"
    static let manual = "manual"
    static let copied = "copied"
    static let escape = "escape"
    static let outsideClick = "outside_click"
    static let appResigned = "app_resigned"
}

private final class DockPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
