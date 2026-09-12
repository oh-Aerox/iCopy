import Foundation

enum ClipboardKind: String, Codable {
    case text
    case image
}

struct ClipboardItem: Codable, Identifiable, Equatable {
    let id: UUID
    let kind: ClipboardKind
    let text: String
    let imageFilename: String?
    let fingerprint: String
    var createdAt: Date

    var previewText: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return L10n.imageKind
        }
        if trimmed.count <= ClipboardLimits.textPreviewLimit {
            return trimmed
        }
        let end = trimmed.index(trimmed.startIndex, offsetBy: ClipboardLimits.textPreviewLimit)
        return String(trimmed[..<end])
    }
}

struct AppSettings: Codable, Equatable {
    var retentionCount: Int
    /// Zero means keep items until the count cap removes them.
    var expiryDays: Int

    static let `default` = AppSettings(
        retentionCount: ClipboardLimits.defaultRetentionCount,
        expiryDays: ClipboardLimits.defaultExpiryDays
    )

    var sanitized: AppSettings {
        var copy = self
        copy.retentionCount = min(
            max(retentionCount, ClipboardLimits.minRetentionCount),
            ClipboardLimits.maxRetentionCount
        )
        if !ClipboardLimits.expiryDayPresets.contains(expiryDays) {
            copy.expiryDays = ClipboardLimits.defaultExpiryDays
        }
        return copy
    }
}

struct CapturedClipboard {
    let kind: ClipboardKind
    let text: String
    let image: EncodedImage?
    let fingerprint: String
}

struct EncodedImage {
    let pngData: Data
    let filename: String
}

enum HistoryPolicy {
    /// Apply expiry first, then the count cap, so a smaller cap still drops stale items.
    static func trimmed(
        _ items: [ClipboardItem],
        settings: AppSettings,
        now: Date = Date()
    ) -> [ClipboardItem] {
        let living: [ClipboardItem]
        if settings.expiryDays > 0 {
            let ttl = TimeInterval(settings.expiryDays) * 24 * 60 * 60
            living = items.filter { now.timeIntervalSince($0.createdAt) <= ttl }
        } else {
            living = items
        }
        if living.count <= settings.retentionCount {
            return living
        }
        return Array(living.prefix(settings.retentionCount))
    }

    static func matches(_ item: ClipboardItem, query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if needle.isEmpty {
            return true
        }
        return item.text.localizedCaseInsensitiveContains(needle)
            || (item.kind == .image && L10n.imageKind.localizedCaseInsensitiveContains(needle))
    }
}
