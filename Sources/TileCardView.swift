import AppKit

/// A real control so the whole card receives the click; labels would otherwise swallow mouseDown.
final class TileCardView: NSButton {
    let item: ClipboardItem
    var isSelected: Bool = false {
        didSet { borderLayer.borderColor = (isSelected ? AppKitTheme.accent : .clear).cgColor }
    }
    var isCopied: Bool = false {
        didSet { timeLabel.stringValue = isCopied ? L10n.copied : L10n.relativeTime(from: item.createdAt) }
    }

    var onCopy: (() -> Void)?
    var onSelect: (() -> Void)?
    var onDelete: (() -> Void)?

    private let borderLayer = CALayer()
    private let timeLabel = NSTextField(labelWithString: "")
    private let deleteButton = NSButton()

    init(item: ClipboardItem, imageData: Data?) {
        self.item = item
        super.init(frame: NSRect(x: 0, y: 0, width: PanelMetrics.tileSize, height: PanelMetrics.tileSize))
        isBordered = false
        title = ""
        setButtonType(.momentaryChange)
        imagePosition = .noImage
        focusRingType = .none
        target = self
        action = #selector(cardClicked)

        wantsLayer = true
        layer?.backgroundColor = AppKitTheme.paper.cgColor
        layer?.cornerRadius = PanelMetrics.tileCornerRadius
        layer?.masksToBounds = false

        borderLayer.frame = bounds
        borderLayer.cornerRadius = PanelMetrics.tileCornerRadius
        borderLayer.borderWidth = 2
        borderLayer.borderColor = NSColor.clear.cgColor
        layer?.addSublayer(borderLayer)

        let kind = chromeLabel(
            item.kind == .image ? L10n.imageKind : L10n.textKind,
            size: 9,
            weight: .semibold,
            color: AppKitTheme.muted
        )
        kind.frame = NSRect(
            x: PanelMetrics.tileInnerInset,
            y: PanelMetrics.tileSize - 24,
            width: 80,
            height: 12
        )
        addSubview(kind)

        if item.kind == .image, let imageData, let image = NSImage(data: imageData) {
            let imageView = NSImageView(image: image)
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.frame = NSRect(
                x: PanelMetrics.tileInnerInset,
                y: 36,
                width: PanelMetrics.tileSize - PanelMetrics.tileInnerInset * 2,
                height: PanelMetrics.tileImageHeight
            )
            imageView.wantsLayer = true
            imageView.layer?.cornerRadius = PanelMetrics.tileImageCornerRadius
            imageView.layer?.masksToBounds = true
            addSubview(imageView)
        } else {
            let body = chromeLabel(item.previewText, size: 12, weight: .regular, color: AppKitTheme.ink)
            body.maximumNumberOfLines = 6
            body.usesSingleLineMode = false
            body.cell?.wraps = true
            body.cell?.lineBreakMode = .byWordWrapping
            body.frame = NSRect(
                x: PanelMetrics.tileInnerInset,
                y: 32,
                width: PanelMetrics.tileSize - PanelMetrics.tileInnerInset * 2,
                height: 88
            )
            addSubview(body)
        }

        timeLabel.stringValue = L10n.relativeTime(from: item.createdAt)
        styleChromeLabel(timeLabel, size: 10, weight: .regular, color: AppKitTheme.muted)
        timeLabel.frame = NSRect(
            x: PanelMetrics.tileInnerInset,
            y: 10,
            width: PanelMetrics.tileSize - PanelMetrics.tileInnerInset * 2,
            height: 14
        )
        addSubview(timeLabel)

        deleteButton.frame = NSRect(
            x: PanelMetrics.tileSize - 26,
            y: PanelMetrics.tileSize - 26,
            width: 16,
            height: 16
        )
        deleteButton.bezelStyle = .circular
        deleteButton.isBordered = false
        deleteButton.image = NSImage(systemSymbolName: "xmark", accessibilityDescription: L10n.deleteItem)
        deleteButton.imageScaling = .scaleProportionallyDown
        deleteButton.contentTintColor = AppKitTheme.ink.withAlphaComponent(0.55)
        deleteButton.target = self
        deleteButton.action = #selector(deleteClicked)
        deleteButton.toolTip = L10n.deleteItem
        addSubview(deleteButton)

        let tracking = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(tracking)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        // The shelf is a floating panel; the first click must paste, not only activate.
        true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        guard bounds.contains(local) else { return nil }
        if deleteButton.frame.contains(local) {
            return deleteButton
        }
        return self
    }

    override func mouseEntered(with event: NSEvent) {
        onSelect?()
    }

    @objc private func cardClicked() {
        AppLog.info("tile.clicked", ["id": item.id.uuidString, "kind": item.kind.rawValue])
        onCopy?()
    }

    @objc private func deleteClicked() {
        onDelete?()
    }

    private func chromeLabel(
        _ text: String,
        size: CGFloat,
        weight: NSFont.Weight,
        color: NSColor
    ) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        styleChromeLabel(field, size: size, weight: weight, color: color)
        return field
    }

    private func styleChromeLabel(
        _ field: NSTextField,
        size: CGFloat,
        weight: NSFont.Weight,
        color: NSColor
    ) {
        field.font = NSFont.systemFont(ofSize: size, weight: weight)
        field.textColor = color
        field.isSelectable = false
        field.isEditable = false
        field.refusesFirstResponder = true
    }
}
