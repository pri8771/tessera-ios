import SwiftUI

/// Concrete, resolved colours for one appearance (light or dark) of a theme.
///
/// Tessera's visual language is "calm gallery": warm, low-saturation surfaces,
/// generous negative space, ink-on-paper contrast, and a single quiet accent.
struct ThemeColors: Equatable {
    var background: Color
    var surface: Color
    var surfaceElevated: Color
    var separator: Color
    var ink: Color
    var inkSecondary: Color
    var inkTertiary: Color
    var accent: Color
    var accentSoft: Color
    var boardWell: Color
    var cellEmpty: Color
    var gridLine: Color
    var success: Color
    var shadow: Color
}

/// A complete visual theme with light + dark variants and a tile palette.
struct Theme: Identifiable, Equatable {
    let id: String
    let name: String
    let tagline: String
    let isPremium: Bool
    let light: ThemeColors
    let dark: ThemeColors
    /// Harmonious fills used to colour the polyomino pieces.
    let tilePalette: [Color]

    func colors(for scheme: ColorScheme) -> ThemeColors {
        scheme == .dark ? dark : light
    }

    /// Deterministic tile colour for a piece index, cycling through the palette.
    func tileColor(forPieceIndex index: Int) -> Color {
        guard !tilePalette.isEmpty else { return light.accent }
        return tilePalette[((index % tilePalette.count) + tilePalette.count) % tilePalette.count]
    }

    /// A small swatch (accent + tiles) for theme previews in the store/settings.
    var previewSwatches: [Color] {
        var swatches = [light.accent]
        swatches.append(contentsOf: tilePalette.prefix(3))
        return swatches
    }
}
