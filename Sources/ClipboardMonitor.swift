import AppKit
import Foundation

/// Watches NSPasteboard.changeCount because macOS does not emit a public clipboard-changed event.
final class ClipboardMonitor {
    private let store: HistoryStore
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: Timer?

    init(store: HistoryStore) {
        self.store = store
    }

    func start() {
        timer = Timer.scheduledTimer(
            withTimeInterval: ClipboardLimits.pollIntervalSeconds,
            repeats: true
        ) { [weak self] _ in
            self?.poll()
        }
        timer?.tolerance = ClipboardLimits.pollIntervalSeconds / 2
    }

    /// Call after we write the pasteboard ourselves so the next poll does not re-ingest the same payload.
    func markExternalWrite() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    private func poll() {
        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount

        if let captured = read(from: pasteboard) {
            store.ingest(captured)
        }
    }

    private func read(from pasteboard: NSPasteboard) -> CapturedClipboard? {
        let image = NSImage(pasteboard: pasteboard)
        let text = pasteboard.string(forType: .string)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Prefer a real image only when there is no useful text; web copies often ship both.
        if let image, !image.tiffRepresentation.isNilOrEmpty, text.isEmpty {
            guard let encoded = ImageCodec.encode(image) else { return nil }
            return CapturedClipboard(
                kind: .image,
                text: "",
                image: encoded,
                fingerprint: ImageCodec.fingerprint(pngData: encoded.pngData)
            )
        }

        if !text.isEmpty {
            return CapturedClipboard(
                kind: .text,
                text: text,
                image: nil,
                fingerprint: ImageCodec.fingerprint(text: text)
            )
        }

        return nil
    }
}

private extension Optional where Wrapped == Data {
    var isNilOrEmpty: Bool {
        switch self {
        case .none:
            return true
        case .some(let data):
            return data.isEmpty
        }
    }
}
