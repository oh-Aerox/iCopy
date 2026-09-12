import AppKit

final class DockContentView: NSView, NSSearchFieldDelegate {
    private let store: HistoryStore
    private let onCopy: (ClipboardItem) -> Void
    private let onHide: () -> Void

    private let searchField = NSSearchField()
    private let scrollView = NSScrollView()
    private let tilesRow = NSView()
    private let emptyTitle = NSTextField(labelWithString: "")
    private let emptyHint = NSTextField(labelWithString: "")
    private let settingsButton = NSButton()
    private let settingsPopover = NSPopover()

    private var tileViews: [TileCardView] = []
    private var selectedID: UUID?
    private var copiedID: UUID?

    init(store: HistoryStore, onCopy: @escaping (ClipboardItem) -> Void, onHide: @escaping () -> Void) {
        self.store = store
        self.onCopy = onCopy
        self.onHide = onHide
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = AppKitTheme.shelf.cgColor
        layer?.cornerRadius = PanelMetrics.cornerRadius
        layer?.masksToBounds = true
        buildChrome()
        store.onChange = { [weak self] in
            self?.reloadTiles()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        reloadTiles()
        window?.makeFirstResponder(searchField)
    }

    func focusSearch() {
        window?.makeFirstResponder(searchField)
    }

    func dismissOverlays() {
        settingsPopover.close()
    }

    func moveSelection(_ delta: Int) {
        let items = filteredItems()
        guard !items.isEmpty else { return }
        let current = items.firstIndex(where: { $0.id == selectedID }) ?? 0
        let next = min(max(current + delta, 0), items.count - 1)
        selectedID = items[next].id
        applySelection()
    }

    func copySelected() {
        let items = filteredItems()
        guard let selectedID, let item = items.first(where: { $0.id == selectedID }) else { return }
        copyItem(item)
    }

    func controlTextDidChange(_ obj: Notification) {
        selectedID = filteredItems().first?.id
        reloadTiles()
    }

    private func buildChrome() {
        searchField.placeholderString = L10n.searchPlaceholder
        searchField.focusRingType = .none
        searchField.delegate = self
        addSubview(searchField)

        let hotkey = NSTextField(labelWithString: HotKeyConfig.displaySymbol)
        hotkey.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        hotkey.textColor = AppKitTheme.paperOnShelf.withAlphaComponent(0.45)
        hotkey.tag = 901
        addSubview(hotkey)

        settingsButton.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: L10n.settingsTitle)
        settingsButton.isBordered = false
        settingsButton.bezelStyle = .regularSquare
        settingsButton.contentTintColor = AppKitTheme.paperOnShelf
        settingsButton.target = self
        settingsButton.action = #selector(toggleSettings)
        settingsButton.toolTip = L10n.settingsTitle
        addSubview(settingsButton)

        scrollView.drawsBackground = false
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.horizontalScrollElasticity = .allowed
        scrollView.documentView = tilesRow
        addSubview(scrollView)

        emptyTitle.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        emptyTitle.textColor = AppKitTheme.paperOnShelf
        emptyTitle.alignment = .center
        addSubview(emptyTitle)

        emptyHint.font = NSFont.systemFont(ofSize: 12)
        emptyHint.textColor = AppKitTheme.paperOnShelf.withAlphaComponent(0.55)
        emptyHint.alignment = .center
        addSubview(emptyHint)

        settingsPopover.behavior = .transient
        settingsPopover.contentViewController = SettingsViewController(store: store)
    }

    override func layout() {
        super.layout()
        let padding = PanelMetrics.panelPadding
        let chromeHeight = PanelMetrics.chromeHeight
        searchField.frame = NSRect(
            x: padding,
            y: bounds.height - padding - chromeHeight,
            width: bounds.width - padding * 2 - 88,
            height: chromeHeight
        )
        if let hotkey = subviews.first(where: { $0.tag == 901 }) {
            hotkey.frame = NSRect(
                x: bounds.width - padding - 78,
                y: bounds.height - padding - chromeHeight + 8,
                width: 44,
                height: 16
            )
        }
        settingsButton.frame = NSRect(
            x: bounds.width - padding - 28,
            y: bounds.height - padding - chromeHeight + 4,
            width: 24,
            height: 24
        )
        scrollView.frame = NSRect(
            x: padding,
            y: padding,
            width: bounds.width - padding * 2,
            height: PanelMetrics.tileSize + 18
        )
        emptyTitle.frame = NSRect(x: padding, y: bounds.midY + 4, width: bounds.width - padding * 2, height: 22)
        emptyHint.frame = NSRect(x: padding, y: bounds.midY - 22, width: bounds.width - padding * 2, height: 20)
    }

    private func filteredItems() -> [ClipboardItem] {
        store.items.filter { HistoryPolicy.matches($0, query: searchField.stringValue) }
    }

    private func reloadTiles() {
        tilesRow.subviews.forEach { $0.removeFromSuperview() }
        tileViews.removeAll()

        let items = filteredItems()
        if selectedID == nil || !items.contains(where: { $0.id == selectedID }) {
            selectedID = items.first?.id
        }

        let empty = items.isEmpty
        emptyTitle.isHidden = !empty
        emptyHint.isHidden = !empty
        scrollView.isHidden = empty
        emptyTitle.stringValue = searchField.stringValue.isEmpty ? L10n.emptyTitle : L10n.noSearchResults
        emptyHint.stringValue = searchField.stringValue.isEmpty ? L10n.emptyHint : L10n.noSearchResults

        var x: CGFloat = 0
        for item in items {
            let tile = TileCardView(item: item, imageData: store.imageData(for: item))
            tile.frame.origin = CGPoint(x: x, y: 4)
            tile.isSelected = item.id == selectedID
            tile.isCopied = item.id == copiedID
            tile.onSelect = { [weak self] in self?.selectedID = item.id; self?.applySelection() }
            tile.onCopy = { [weak self] in self?.copyItem(item) }
            tile.onDelete = { [weak self] in self?.store.delete(item.id) }
            tilesRow.addSubview(tile)
            tileViews.append(tile)
            x += PanelMetrics.tileSize + PanelMetrics.tileSpacing
        }
        tilesRow.frame = NSRect(
            x: 0,
            y: 0,
            width: max(x, scrollView.contentSize.width),
            height: PanelMetrics.tileSize + 8
        )
    }

    private func applySelection() {
        for tile in tileViews {
            tile.isSelected = tile.item.id == selectedID
            if tile.isSelected {
                tile.scrollToVisible(tile.bounds)
            }
        }
    }

    private func copyItem(_ item: ClipboardItem) {
        AppLog.info("tile.paste_requested", ["id": item.id.uuidString])
        copiedID = item.id
        applySelection()
        for tile in tileViews {
            tile.isCopied = tile.item.id == item.id
        }
        onCopy(item)
    }

    @objc private func toggleSettings() {
        if settingsPopover.isShown {
            settingsPopover.close()
            return
        }
        settingsPopover.contentViewController = SettingsViewController(store: store)
        settingsPopover.show(relativeTo: settingsButton.bounds, of: settingsButton, preferredEdge: .minY)
    }
}
