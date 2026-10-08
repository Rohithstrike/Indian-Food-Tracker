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
    // Indigo Dusk. Dark: deep ink with a faint indigo cast, ivory text, copper accent. Light: warm ivory with ink-indigo text.
    // Backgrounds and surfaces
    static let background          = AppColorPair(light: 0xF8F4EC, dark: 0x0F0F15)
    static let backgroundSecondary = AppColorPair(light: 0xEFE9DE, dark: 0x14141B)
    static let surface             = AppColorPair(light: 0xFFFFFF, dark: 0x1B1B24)
    static let surfaceElevated     = AppColorPair(light: 0xFFFFFF, dark: 0x252530)

    // Brand: restrained ember (terracotta). Use sparingly.
    static let primary             = AppColorPair(light: 0xB04A2E, dark: 0xCC9166)
    static let primaryForeground   = AppColorPair(light: 0xFFFFFF, dark: 0x0F0F15)
    static let accent              = AppColorPair(light: 0x9E4228, dark: 0xDDA77E)

    // Text
    static let textPrimary         = AppColorPair(light: 0x151A33, dark: 0xF4EFE6)
    static let textSecondary       = AppColorPair(light: 0x555B78, dark: 0xB9B5BF)
    static let textTertiary        = AppColorPair(light: 0x62677F, dark: 0x8F8C9A)

    // Structure
    static let divider             = AppColorPair(light: 0xE2DACB, dark: 0x2F2F3D)

    // Status (unchanged)
    static let success             = AppColorPair(light: 0x2E7D4F, dark: 0x5DBB82)
    static let warning             = AppColorPair(light: 0x9A5B00, dark: 0xE5A33A)
    static let error               = AppColorPair(light: 0xB3261E, dark: 0xF2877F)

    // Nutrients (always shown with a text label too, never color alone)
    static let protein             = AppColorPair(light: 0x2F6B8A, dark: 0x6FB3D2)
    static let carbs               = AppColorPair(light: 0xA86F0E, dark: 0xE3B04B)
    static let fat                 = AppColorPair(light: 0x8A5A8F, dark: 0xC79BCB)
    static let fiber               = AppColorPair(light: 0x5C7A29, dark: 0xA8C672)
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
    static let fiber               = AppPalette.fiber.color
}
