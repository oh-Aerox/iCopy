import AppKit
import Foundation

enum PasteboardWriter {
    static func copy(_ item: ClipboardItem, store: HistoryStore, monitor: ClipboardMonitor) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.kind {
        case .text:
            pasteboard.setString(item.text, forType: .string)
        case .image:
            if let data = store.imageData(for: item), let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
            } else if !item.text.isEmpty {
                pasteboard.setString(item.text, forType: .string)
            }
        }

        monitor.markExternalWrite()
        AppLog.info("clipboard.restored", ["kind": item.kind.rawValue, "id": item.id.uuidString])
    }
}
