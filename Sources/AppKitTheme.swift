import AppKit

enum AppKitTheme {
    static let shelf = NSColor(
        srgbRed: Palette.shelfRed,
        green: Palette.shelfGreen,
        blue: Palette.shelfBlue,
        alpha: 0.94
    )
    static let paper = NSColor(
        srgbRed: Palette.paperRed,
        green: Palette.paperGreen,
        blue: Palette.paperBlue,
        alpha: 1
    )
    static let ink = NSColor(
        srgbRed: Palette.inkRed,
        green: Palette.inkGreen,
        blue: Palette.inkBlue,
        alpha: 1
    )
    static let accent = NSColor(
        srgbRed: Palette.accentRed,
        green: Palette.accentGreen,
        blue: Palette.accentBlue,
        alpha: 1
    )
    static let muted = NSColor(
        srgbRed: Palette.mutedRed,
        green: Palette.mutedGreen,
        blue: Palette.mutedBlue,
        alpha: 1
    )
    static let chromeFill = NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.08)
    static let paperOnShelf = NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.72)
}
