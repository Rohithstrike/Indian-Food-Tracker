import SwiftUI
import UIKit

/// A color with one value for Light Mode and one for Dark Mode (stored as 0xRRGGBB).
struct AppColorPair {
    let light: UInt32
    let dark: UInt32

    /// A SwiftUI color that switches automatically with the system appearance.
    var color: Color {
        let light = self.light
        let dark = self.dark
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? uiColor(hex: dark) : uiColor(hex: light)
        })
    }
}

nonisolated private func uiColor(hex: UInt32) -> UIColor {
    UIColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: 1
    )
}

/// The raw light/dark values. Kept separate so tests can check contrast with math.
enum AppPalette {
    // Backgrounds and surfaces: warm off-white / warm near-black
    static let background          = AppColorPair(light: 0xFAF6F0, dark: 0x1A1614)
    static let backgroundSecondary = AppColorPair(light: 0xF2EBE2, dark: 0x221D1A)
    static let surface             = AppColorPair(light: 0xFFFFFF, dark: 0x2A2420)
    static let surfaceElevated     = AppColorPair(light: 0xFFFFFF, dark: 0x352E29)

    // Brand: muted paprika / terracotta
    static let primary             = AppColorPair(light: 0xB5472A, dark: 0xE58A6B)
    static let primaryForeground   = AppColorPair(light: 0xFFFFFF, dark: 0x1A1614)
    static let accent              = AppColorPair(light: 0xA23E22, dark: 0xEE9B7E)

    // Text: warm charcoal
    static let textPrimary         = AppColorPair(light: 0x2B2420, dark: 0xF5EFE8)
    static let textSecondary       = AppColorPair(light: 0x6B5F57, dark: 0xBDB1A7)
    static let textTertiary        = AppColorPair(light: 0x7A6E65, dark: 0x9A8E85)

    // Structure
    static let divider             = AppColorPair(light: 0xE4DACD, dark: 0x3D3530)

    // Status
    static let success             = AppColorPair(light: 0x2E7D4F, dark: 0x5DBB82)
    static let warning             = AppColorPair(light: 0x9A5B00, dark: 0xE5A33A)
    static let error               = AppColorPair(light: 0xB3261E, dark: 0xF2877F)

    // Macronutrients (always shown with a text label too, never color alone)
    static let protein             = AppColorPair(light: 0x2F6B8A, dark: 0x6FB3D2)
    static let carbs               = AppColorPair(light: 0xA86F0E, dark: 0xE3B04B)
    static let fat                 = AppColorPair(light: 0x8A5A8F, dark: 0xC79BCB)
}

/// The colors the app uses. Always use these instead of raw colors in views.
enum AppColor {
    static let background          = AppPalette.background.color
    static let backgroundSecondary = AppPalette.backgroundSecondary.color
    static let surface             = AppPalette.surface.color
    static let surfaceElevated     = AppPalette.surfaceElevated.color

    static let primary             = AppPalette.primary.color
    static let primaryForeground   = AppPalette.primaryForeground.color
    static let accent              = AppPalette.accent.color

    static let textPrimary         = AppPalette.textPrimary.color
    static let textSecondary       = AppPalette.textSecondary.color
    static let textTertiary        = AppPalette.textTertiary.color

    static let divider             = AppPalette.divider.color

    static let success             = AppPalette.success.color
    static let warning             = AppPalette.warning.color
    static let error               = AppPalette.error.color

    static let protein             = AppPalette.protein.color
    static let carbs               = AppPalette.carbs.color
    static let fat                 = AppPalette.fat.color
}
