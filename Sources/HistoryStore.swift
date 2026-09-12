import Foundation

/// Owns history and settings. All callers must hop to the main thread because UI and the poller share this object.
final class HistoryStore {
    private(set) var items: [ClipboardItem] = []
    var settings: AppSettings = .default {
        didSet {
            // Persist immediately so a quit during settings edits cannot lose the cap.
            if oldValue != settings {
                applyRetention()
                persistSettings()
                onChange?()
            }
        }
    }

    var onChange: (() -> Void)?

    func load() {
        do {
            try AppPaths.prepare()
        } catch {
            AppLog.error("storage.prepare_failed", ["reason": error.localizedDescription])
        }

        settings = readJSON(AppPaths.settingsFile, as: AppSettings.self)?.sanitized ?? .default
        items = HistoryPolicy.trimmed(
            readJSON(AppPaths.historyFile, as: [ClipboardItem].self) ?? [],
            settings: settings
        )
        AppLog.info("history.loaded", [
            "count": String(items.count),
            "retention": String(settings.retentionCount),
            "expiryDays": String(settings.expiryDays),
        ])
    }

    func ingest(_ captured: CapturedClipboard) {
        if let existingIndex = items.firstIndex(where: { $0.fingerprint == captured.fingerprint }) {
            var existing = items.remove(at: existingIndex)
            existing.createdAt = Date()
            items.insert(existing, at: 0)
            persistHistory()
            onChange?()
            return
        }

        var imageFilename: String?
        if let image = captured.image {
            do {
                try image.pngData.write(to: AppPaths.imageURL(image.filename), options: .atomic)
                imageFilename = image.filename
            } catch {
                AppLog.error("image.write_failed", ["reason": error.localizedDescription])
            }
        }

        let item = ClipboardItem(
            id: UUID(),
            kind: captured.kind,
            text: captured.text,
            imageFilename: imageFilename,
            fingerprint: captured.fingerprint,
            createdAt: Date()
        )
        items.insert(item, at: 0)
        applyRetention()
        persistHistory()
        onChange?()
        AppLog.info("clipboard.captured", [
            "kind": captured.kind.rawValue,
            "count": String(items.count),
        ])
    }

    func delete(_ id: UUID) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        items.removeAll { $0.id == id }
        if let filename = item.imageFilename {
            try? FileManager.default.removeItem(at: AppPaths.imageURL(filename))
        }
        persistHistory()
        onChange?()
        AppLog.info("history.deleted", ["id": id.uuidString])
    }

    func imageData(for item: ClipboardItem) -> Data? {
        guard let filename = item.imageFilename else { return nil }
        return try? Data(contentsOf: AppPaths.imageURL(filename))
    }

    private func applyRetention() {
        let before = items
        items = HistoryPolicy.trimmed(items, settings: settings.sanitized)
        let removed = Set(before.map(\.id)).subtracting(items.map(\.id))
        for item in before where removed.contains(item.id) {
            if let filename = item.imageFilename {
                try? FileManager.default.removeItem(at: AppPaths.imageURL(filename))
            }
        }
        if before.count != items.count {
            persistHistory()
            AppLog.info("history.trimmed", [
                "before": String(before.count),
                "after": String(items.count),
            ])
        }
    }

    private func persistHistory() {
        writeJSON(items, to: AppPaths.historyFile)
    }

    private func persistSettings() {
        writeJSON(settings.sanitized, to: AppPaths.settingsFile)
        AppLog.info("settings.saved", [
            "retention": String(settings.retentionCount),
            "expiryDays": String(settings.expiryDays),
        ])
    }

    private func readJSON<T: Decodable>(_ url: URL, as type: T.Type) -> T? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(type, from: data)
        } catch {
            AppLog.error("storage.read_failed", [
                "file": url.lastPathComponent,
                "reason": error.localizedDescription,
            ])
            return nil
        }
    }

    private func writeJSON<T: Encodable>(_ value: T, to url: URL) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            AppLog.error("storage.write_failed", [
                "file": url.lastPathComponent,
                "reason": error.localizedDescription,
            ])
        }
    }
}
