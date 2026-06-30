import SwiftUI

/// The catalogue of bundled themes. "Daybreak" is free; the rest unlock with
/// Tessera Pro (or, in a future build, as standalone theme IAPs).
enum ThemeCatalog {

    static let all: [Theme] = [daybreak, aurora, dusk, meadow, ink]

    static let freeThemeID = "daybreak"

    static func theme(withID id: String) -> Theme {
        all.first { $0.id == id } ?? daybreak
    }

    static var freeThemes: [Theme] { all.filter { !$0.isPremium } }
    static var premiumThemes: [Theme] { all.filter(\.isPremium) }

    // MARK: - Daybreak (free) — warm paper & terracotta

    static let daybreak = Theme(
        id: "daybreak",
        name: "Daybreak",
        tagline: "Warm paper and clay",
        isPremium: false,
        light: ThemeColors(
            background: Color(hex: "F4EFE7"),
            surface: Color(hex: "FBF8F2"),
            surfaceElevated: Color(hex: "FFFFFF"),
            separator: Color(hex: "E4DACA"),
            ink: Color(hex: "2B2724"),
            inkSecondary: Color(hex: "6B6358"),
            inkTertiary: Color(hex: "9A9082"),
            accent: Color(hex: "C2693F"),
            accentSoft: Color(hex: "EAD3C4"),
            boardWell: Color(hex: "EAE3D7"),
            cellEmpty: Color(hex: "E1D8C8"),
            gridLine: Color(hex: "D5CAB6"),
            success: Color(hex: "5E8B6A"),
            shadow: Color(hex: "2B272414")
        ),
        dark: ThemeColors(
            background: Color(hex: "1A1714"),
            surface: Color(hex: "241F1A"),
            surfaceElevated: Color(hex: "2E2822"),
            separator: Color(hex: "3A332A"),
            ink: Color(hex: "F2EBDF"),
            inkSecondary: Color(hex: "B7AC9B"),
            inkTertiary: Color(hex: "7E7567"),
            accent: Color(hex: "E08A5B"),
            accentSoft: Color(hex: "4A372C"),
            boardWell: Color(hex: "141210"),
            cellEmpty: Color(hex: "2C261F"),
            gridLine: Color(hex: "3A332A"),
            success: Color(hex: "84B690"),
            shadow: Color(hex: "00000040")
        ),
        tilePalette: [
            Color(hex: "C2693F"), Color(hex: "7C9A8E"), Color(hex: "D8A657"),
            Color(hex: "9A6A8C"), Color(hex: "6B86A8"), Color(hex: "B47B5E")
        ]
    )

    // MARK: - Aurora (premium) — cool teal & indigo

    static let aurora = Theme(
        id: "aurora",
        name: "Aurora",
        tagline: "Cool light over water",
        isPremium: true,
        light: ThemeColors(
            background: Color(hex: "ECF1F3"),
            surface: Color(hex: "F7FAFB"),
            surfaceElevated: Color(hex: "FFFFFF"),
            separator: Color(hex: "D7E1E6"),
            ink: Color(hex: "1E2A2F"),
            inkSecondary: Color(hex: "566970"),
            inkTertiary: Color(hex: "8DA0A7"),
            accent: Color(hex: "2E8B8B"),
            accentSoft: Color(hex: "CDE5E4"),
            boardWell: Color(hex: "DFE8EC"),
            cellEmpty: Color(hex: "D3DFE4"),
            gridLine: Color(hex: "C2D2D8"),
            success: Color(hex: "3F9D7C"),
            shadow: Color(hex: "1E2A2F14")
        ),
        dark: ThemeColors(
            background: Color(hex: "0F1719"),
            surface: Color(hex: "172225"),
            surfaceElevated: Color(hex: "1F2D31"),
            separator: Color(hex: "2A3A3F"),
            ink: Color(hex: "E6F0F2"),
            inkSecondary: Color(hex: "9FB4BA"),
            inkTertiary: Color(hex: "6A7E84"),
            accent: Color(hex: "4FBDB8"),
            accentSoft: Color(hex: "1E3A3A"),
            boardWell: Color(hex: "0A1113"),
            cellEmpty: Color(hex: "1C292D"),
            gridLine: Color(hex: "2A3A3F"),
            success: Color(hex: "59C79B"),
            shadow: Color(hex: "00000040")
        ),
        tilePalette: [
            Color(hex: "2E8B8B"), Color(hex: "5C7FB3"), Color(hex: "73B0A6"),
            Color(hex: "8C6FB0"), Color(hex: "4F9CC4"), Color(hex: "C28E6B")
        ]
    )

    // MARK: - Dusk (premium) — plum & rose

    static let dusk = Theme(
        id: "dusk",
        name: "Dusk",
        tagline: "Plum sky, fading light",
        isPremium: true,
        light: ThemeColors(
            background: Color(hex: "F1ECF1"),
            surface: Color(hex: "FAF6FA"),
            surfaceElevated: Color(hex: "FFFFFF"),
            separator: Color(hex: "E1D6E2"),
            ink: Color(hex: "2A2230"),
            inkSecondary: Color(hex: "665A6E"),
            inkTertiary: Color(hex: "9A8DA1"),
            accent: Color(hex: "9A5B86"),
            accentSoft: Color(hex: "E7D3E0"),
            boardWell: Color(hex: "E7DEE7"),
            cellEmpty: Color(hex: "DCD0DD"),
            gridLine: Color(hex: "CDBFCF"),
            success: Color(hex: "6E8C72"),
            shadow: Color(hex: "2A223014")
        ),
        dark: ThemeColors(
            background: Color(hex: "16121A"),
            surface: Color(hex: "201A26"),
            surfaceElevated: Color(hex: "2A2231"),
            separator: Color(hex: "382E40"),
            ink: Color(hex: "EFE7F1"),
            inkSecondary: Color(hex: "B3A6B9"),
            inkTertiary: Color(hex: "7C6F83"),
            accent: Color(hex: "C885AC"),
            accentSoft: Color(hex: "3A2C38"),
            boardWell: Color(hex: "100D14"),
            cellEmpty: Color(hex: "271F2D"),
            gridLine: Color(hex: "382E40"),
            success: Color(hex: "8FB593"),
            shadow: Color(hex: "00000040")
        ),
        tilePalette: [
            Color(hex: "9A5B86"), Color(hex: "6E6BA8"), Color(hex: "C07C8A"),
            Color(hex: "7FA0A6"), Color(hex: "B58AB8"), Color(hex: "C49A6C")
        ]
    )

    // MARK: - Meadow (premium) — soft greens

    static let meadow = Theme(
        id: "meadow",
        name: "Meadow",
        tagline: "Quiet green hours",
        isPremium: true,
        light: ThemeColors(
            background: Color(hex: "EDF1E9"),
            surface: Color(hex: "F7FAF3"),
            surfaceElevated: Color(hex: "FFFFFF"),
            separator: Color(hex: "DBE3D2"),
            ink: Color(hex: "232A22"),
            inkSecondary: Color(hex: "5A6655"),
            inkTertiary: Color(hex: "8D9886"),
            accent: Color(hex: "5C8A4F"),
            accentSoft: Color(hex: "D6E5CB"),
            boardWell: Color(hex: "E2E9DA"),
            cellEmpty: Color(hex: "D6DECB"),
            gridLine: Color(hex: "C5D0B8"),
            success: Color(hex: "4F9D6A"),
            shadow: Color(hex: "232A2214")
        ),
        dark: ThemeColors(
            background: Color(hex: "12150F"),
            surface: Color(hex: "1B2016"),
            surfaceElevated: Color(hex: "232A1D"),
            separator: Color(hex: "323A29"),
            ink: Color(hex: "EAF0E2"),
            inkSecondary: Color(hex: "A8B49C"),
            inkTertiary: Color(hex: "707C64"),
            accent: Color(hex: "84B26F"),
            accentSoft: Color(hex: "2A361F"),
            boardWell: Color(hex: "0C0F09"),
            cellEmpty: Color(hex: "1F261A"),
            gridLine: Color(hex: "323A29"),
            success: Color(hex: "6FC089"),
            shadow: Color(hex: "00000040")
        ),
        tilePalette: [
            Color(hex: "5C8A4F"), Color(hex: "8AA661"), Color(hex: "C4A85A"),
            Color(hex: "6E9E8C"), Color(hex: "A9863F"), Color(hex: "7E8C5A")
        ]
    )

    // MARK: - Ink (premium) — gallery monochrome

    static let ink = Theme(
        id: "ink",
        name: "Ink",
        tagline: "Gallery monochrome",
        isPremium: true,
        light: ThemeColors(
            background: Color(hex: "EDEDEC"),
            surface: Color(hex: "F8F8F7"),
            surfaceElevated: Color(hex: "FFFFFF"),
            separator: Color(hex: "DCDCDA"),
            ink: Color(hex: "1C1C1B"),
            inkSecondary: Color(hex: "5C5C5A"),
            inkTertiary: Color(hex: "919190"),
            accent: Color(hex: "3A3A38"),
            accentSoft: Color(hex: "D8D8D6"),
            boardWell: Color(hex: "E2E2E0"),
            cellEmpty: Color(hex: "D6D6D4"),
            gridLine: Color(hex: "C6C6C3"),
            success: Color(hex: "4F7A5E"),
            shadow: Color(hex: "1C1C1B14")
        ),
        dark: ThemeColors(
            background: Color(hex: "121211"),
            surface: Color(hex: "1C1C1B"),
            surfaceElevated: Color(hex: "262625"),
            separator: Color(hex: "333332"),
            ink: Color(hex: "F0F0EE"),
            inkSecondary: Color(hex: "AEAEAB"),
            inkTertiary: Color(hex: "6E6E6C"),
            accent: Color(hex: "D8D8D4"),
            accentSoft: Color(hex: "303030"),
            boardWell: Color(hex: "0C0C0B"),
            cellEmpty: Color(hex: "212120"),
            gridLine: Color(hex: "333332"),
            success: Color(hex: "78A988"),
            shadow: Color(hex: "00000040")
        ),
        tilePalette: [
            Color(hex: "4A4A48"), Color(hex: "6E6E6B"), Color(hex: "8C8C89"),
            Color(hex: "5A5A57"), Color(hex: "9E9E9A"), Color(hex: "7B7B78")
        ]
    )
}
