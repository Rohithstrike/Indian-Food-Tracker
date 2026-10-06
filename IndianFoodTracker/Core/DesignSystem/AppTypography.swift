import SwiftUI

/// Semantic text styles. All use Apple's system fonts and scale with Dynamic Type.
enum AppTypography {
    static let largeTitle  = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let title       = Font.system(.title2, design: .rounded, weight: .semibold)
    static let headline    = Font.system(.headline, design: .default, weight: .semibold)
    static let body        = Font.system(.body)
    static let callout     = Font.system(.callout)
    static let caption     = Font.system(.caption)

    /// Numbers that should stand out (e.g. a macro total).
    static let numberLarge  = Font.system(.title, design: .rounded, weight: .bold)
    static let numberMedium = Font.system(.title3, design: .rounded, weight: .semibold)

    /// Small label that sits beside or under a number (e.g. "kcal", "g").
    static let unitLabel   = Font.system(.subheadline, design: .rounded, weight: .medium)

    /// Text inside buttons.
    static let button      = Font.system(.headline, design: .rounded, weight: .semibold)

    /// The big calorie number. Its size is scaled for Dynamic Type inside
    /// NutritionMetric (a fixed base size can't scale on its own).
    static let calorieHeroBaseSize: CGFloat = 64
}
