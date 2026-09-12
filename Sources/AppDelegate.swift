import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var store: HistoryStore!
    private var monitor: ClipboardMonitor!
    private var hotKey: HotKeyMonitor!
    private var panel: DockPanelController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        store = HistoryStore()
        store.load()
        monitor = ClipboardMonitor(store: store)
        monitor.start()
        panel = DockPanelController(store: store) { [weak self] item in
            guard let self else { return }
            PasteboardWriter.copy(item, store: self.store, monitor: self.monitor)
        }
        hotKey = HotKeyMonitor()
        hotKey.register { [weak self] in
            self?.panel.toggle()
        }
        installStatusItem()
        AppLog.info("app.launched", [
            "retention": String(store.settings.retentionCount),
            "arch": "arm64",
        ])
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panel.show()
        return true
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: L10n.statusItemDescription
            )
            button.toolTip = L10n.appName
        }

        let menu = NSMenu()
        menu.addItem(withTitle: L10n.showPanel, action: #selector(showPanel), keyEquivalent: "v")
            .keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: L10n.quit, action: #selector(quit), keyEquivalent: "q")
        item.menu = menu
        statusItem = item
    }

    @objc private func showPanel() {
        panel.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
