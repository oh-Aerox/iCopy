import AppKit

final class SettingsViewController: NSViewController {
    private let store: HistoryStore
    private let customField = NSTextField()

    init(store: HistoryStore) {
        self.store = store
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: PanelMetrics.settingsWidth, height: PanelMetrics.settingsPanelHeight))
        build()
    }

    private func build() {
        let root = view

        let title = label(L10n.settingsTitle, size: 14, weight: .semibold)
        title.frame = NSRect(x: 16, y: 176, width: 200, height: 20)
        root.addSubview(title)

        let retention = label(L10n.retentionLabel, size: 12, weight: .medium)
        retention.textColor = .secondaryLabelColor
        retention.frame = NSRect(x: 16, y: 150, width: 200, height: 16)
        root.addSubview(retention)

        var x: CGFloat = 16
        for count in ClipboardLimits.retentionPresets {
            let button = chip(
                title: "\(count) \(L10n.retentionUnit)",
                selected: store.settings.retentionCount == count
            )
            button.frame = NSRect(x: x, y: 118, width: 72, height: 26)
            button.tag = count
            button.action = #selector(selectRetention(_:))
            root.addSubview(button)
            x += 80
        }

        let custom = label(L10n.customRetention, size: 12, weight: .regular)
        custom.frame = NSRect(x: 16, y: 88, width: 56, height: 22)
        root.addSubview(custom)

        customField.frame = NSRect(x: 76, y: 86, width: PanelMetrics.customRetentionFieldWidth, height: 24)
        customField.placeholderString = "\(ClipboardLimits.minRetentionCount)–\(ClipboardLimits.maxRetentionCount)"
        if !ClipboardLimits.retentionPresets.contains(store.settings.retentionCount) {
            customField.stringValue = String(store.settings.retentionCount)
        }
        customField.target = self
        customField.action = #selector(customRetentionChanged)
        root.addSubview(customField)

        let expiry = label(L10n.expiryLabel, size: 12, weight: .medium)
        expiry.textColor = .secondaryLabelColor
        expiry.frame = NSRect(x: 16, y: 56, width: 200, height: 16)
        root.addSubview(expiry)

        x = 16
        for days in ClipboardLimits.expiryDayPresets {
            let title = days == 0 ? L10n.expiryNever : L10n.expiryDays(days)
            let button = chip(title: title, selected: store.settings.expiryDays == days)
            button.frame = NSRect(x: x, y: 22, width: 70, height: 26)
            button.tag = days
            button.action = #selector(selectExpiry(_:))
            root.addSubview(button)
            x += 78
        }
    }

    @objc private func selectRetention(_ sender: NSButton) {
        store.settings.retentionCount = sender.tag
        customField.stringValue = ""
        reload()
    }

    @objc private func customRetentionChanged() {
        if let value = Int(customField.stringValue) {
            store.settings.retentionCount = AppSettings(
                retentionCount: value,
                expiryDays: store.settings.expiryDays
            ).sanitized.retentionCount
        }
        reload()
    }

    @objc private func selectExpiry(_ sender: NSButton) {
        store.settings.expiryDays = sender.tag
        reload()
    }

    private func reload() {
        view.subviews.forEach { $0.removeFromSuperview() }
        build()
    }

    private func label(_ text: String, size: CGFloat, weight: NSFont.Weight) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = NSFont.systemFont(ofSize: size, weight: weight)
        return field
    }

    private func chip(title: String, selected: Bool) -> NSButton {
        let button = NSButton(title: title, target: self, action: nil)
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        if selected {
            button.contentTintColor = .white
            button.bezelColor = AppKitTheme.accent
        }
        return button
    }
}
