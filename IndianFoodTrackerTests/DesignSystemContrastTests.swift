import XCTest
@testable import IndianFoodTracker

@MainActor
final class DesignSystemContrastTests: XCTestCase {

    private func luminance(_ hex: UInt32) -> Double {
        func channel(_ value: UInt32) -> Double {
            let c = Double(value) / 255.0
            return c <= 0.03928
                ? c / 12.92
                : pow((c + 0.055) / 1.055, 2.4)
        }

        return 0.2126 * channel((hex >> 16) & 0xFF)
             + 0.7152 * channel((hex >> 8) & 0xFF)
             + 0.0722 * channel(hex & 0xFF)
    }

    private func contrastRatio(_ a: UInt32, _ b: UInt32) -> Double {
        let first = luminance(a)
        let second = luminance(b)

        return (max(first, second) + 0.05)
             / (min(first, second) + 0.05)
    }

    private func checkContrast(
        _ name: String,
        foreground: AppColorPair,
        background: AppColorPair,
        minimum: Double,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let lightRatio = contrastRatio(
            foreground.light,
            background.light
        )

        let darkRatio = contrastRatio(
            foreground.dark,
            background.dark
        )

        XCTAssertGreaterThanOrEqual(
            lightRatio,
            minimum,
            "\(name) LIGHT contrast is \(lightRatio):1, needs \(minimum):1",
            file: file,
            line: line
        )

        XCTAssertGreaterThanOrEqual(
            darkRatio,
            minimum,
            "\(name) DARK contrast is \(darkRatio):1, needs \(minimum):1",
            file: file,
            line: line
        )
    }

    func testPrimaryTextContrast() {
        checkContrast(
            "Primary text on background",
            foreground: AppPalette.textPrimary,
            background: AppPalette.background,
            minimum: 4.5
        )

        checkContrast(
            "Primary text on surface",
            foreground: AppPalette.textPrimary,
            background: AppPalette.surface,
            minimum: 4.5
        )
    }

    func testSecondaryTextContrast() {
        checkContrast(
            "Secondary text on background",
            foreground: AppPalette.textSecondary,
            background: AppPalette.background,
            minimum: 4.5
        )

        checkContrast(
            "Secondary text on surface",
            foreground: AppPalette.textSecondary,
            background: AppPalette.surface,
            minimum: 4.5
        )
    }

    func testTertiaryTextContrast() {
        checkContrast(
            "Tertiary text on background",
            foreground: AppPalette.textTertiary,
            background: AppPalette.background,
            minimum: 4.5
        )

        checkContrast(
            "Tertiary text on surface",
            foreground: AppPalette.textTertiary,
            background: AppPalette.surface,
            minimum: 4.5
        )
    }

    func testBrandContrast() {
        checkContrast(
            "Primary foreground on primary",
            foreground: AppPalette.primaryForeground,
            background: AppPalette.primary,
            minimum: 4.5
        )

        checkContrast(
            "Accent on background",
            foreground: AppPalette.accent,
            background: AppPalette.background,
            minimum: 4.5
        )

        checkContrast(
            "Accent on surface",
            foreground: AppPalette.accent,
            background: AppPalette.surface,
            minimum: 4.5
        )
    }

    func testStatusContrast() {
        checkContrast(
            "Success on background",
            foreground: AppPalette.success,
            background: AppPalette.background,
            minimum: 4.5
        )

        checkContrast(
            "Warning on background",
            foreground: AppPalette.warning,
            background: AppPalette.background,
            minimum: 4.5
        )

        checkContrast(
            "Error on background",
            foreground: AppPalette.error,
            background: AppPalette.background,
            minimum: 4.5
        )
    }

    func testMacroColorContrast() {
        checkContrast(
            "Protein on surface",
            foreground: AppPalette.protein,
            background: AppPalette.surface,
            minimum: 3.0
        )

        checkContrast(
            "Carbs on surface",
            foreground: AppPalette.carbs,
            background: AppPalette.surface,
            minimum: 3.0
        )

        checkContrast(
            "Fat on surface",
            foreground: AppPalette.fat,
            background: AppPalette.surface,
            minimum: 3.0
        )
    }

    func testFiberColorContrast() {
        // Fiber is a large, bold number with a text label, like the other nutrient colors (3:1).
        checkContrast(
            "Fiber on surface",
            foreground: AppPalette.fiber,
            background: AppPalette.surface,
            minimum: 3.0
        )
        checkContrast(
            "Fiber on background",
            foreground: AppPalette.fiber,
            background: AppPalette.background,
            minimum: 3.0
        )
    }

    func testNutrientColorsAreDistinct() {
        let colors: [(String, AppColorPair)] = [
            ("protein", AppPalette.protein), ("carbs", AppPalette.carbs),
            ("fat", AppPalette.fat), ("fiber", AppPalette.fiber)
        ]
        for i in 0..<colors.count {
            for j in (i + 1)..<colors.count {
                XCTAssertNotEqual(colors[i].1.light, colors[j].1.light,
                                  "\(colors[i].0) and \(colors[j].0) share a LIGHT color")
                XCTAssertNotEqual(colors[i].1.dark, colors[j].1.dark,
                                  "\(colors[i].0) and \(colors[j].0) share a DARK color")
            }
        }
    }
}
