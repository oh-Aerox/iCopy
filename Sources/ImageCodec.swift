import AppKit
import CryptoKit
import Foundation

enum ImageCodec {
    /// Downscale before persist so one screenshot cannot blow past the history cap on disk.
    static func encode(_ image: NSImage) -> EncodedImage? {
        guard let bitmap = rasterized(image) else { return nil }
        guard let png = bitmap.representation(using: .png, properties: [:]) else { return nil }
        if png.count > ClipboardLimits.maxStoredImageBytes {
            AppLog.info("clipboard.image_skipped", ["bytes": String(png.count)])
            return nil
        }
        let digest = SHA256.hash(data: png)
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return EncodedImage(pngData: png, filename: "\(hex).png")
    }

    static func fingerprint(pngData: Data) -> String {
        let digest = SHA256.hash(data: pngData)
        return "i:" + digest.map { String(format: "%02x", $0) }.joined()
    }

    static func fingerprint(text: String) -> String {
        let digest = SHA256.hash(data: Data(text.utf8))
        return "t:" + digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func rasterized(_ image: NSImage) -> NSBitmapImageRep? {
        guard image.size.width > 0, image.size.height > 0 else { return nil }
        let longest = max(image.size.width, image.size.height)
        let scale = longest > ClipboardLimits.maxStoredImageEdge
            ? ClipboardLimits.maxStoredImageEdge / longest
            : 1
        let size = NSSize(
            width: max(1, (image.size.width * scale).rounded()),
            height: max(1, (image.size.height * scale).rounded())
        )
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(
            in: NSRect(origin: .zero, size: size),
            from: .zero,
            operation: .copy,
            fraction: 1
        )
        NSGraphicsContext.restoreGraphicsState()
        return rep
    }
}
