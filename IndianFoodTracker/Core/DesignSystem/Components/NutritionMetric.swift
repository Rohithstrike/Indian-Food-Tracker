import SwiftUI

/// A big number with a small unit label, e.g. "1,482" over "kcal".
/// VoiceOver reads it as one phrase, e.g. "1,482 kilocalories".
struct NutritionMetric: View {
    enum Size {
        case hero    // the main calorie number
        case large   // macro totals
        case medium  // smaller figures
    }

    let value: String
    let unit: String
    var spokenUnit: String? = nil
    var size: Size = .large
    var valueColor: Color = AppColor.textPrimary

    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = AppTypography.calorieHeroBaseSize

    private var valueFont: Font {
        switch size {
        case .hero:   return .system(size: heroSize, weight: .bold, design: .rounded)
        case .large:  return AppTypography.numberLarge
        case .medium: return AppTypography.numberMedium
        }
    }

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text(value)
                .font(valueFont)
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(unit)
                .font(AppTypography.unitLabel)
                .foregroundStyle(AppColor.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(spokenUnit ?? unit)")
    }
}

#Preview("Light") {
    VStack(spacing: Spacing.l) {
        NutritionMetric(value: "1,482", unit: "kcal", spokenUnit: "kilocalories", size: .hero)
        NutritionMetric(value: "82", unit: "g protein", spokenUnit: "grams of protein",
                        size: .large, valueColor: AppColor.protein)
        NutritionMetric(value: "165", unit: "g carbs", spokenUnit: "grams of carbohydrates",
                        size: .medium, valueColor: AppColor.carbs)
    }
    .padding(Spacing.l)
    .background(AppColor.background)
}

#Preview("Dark") {
    VStack(spacing: Spacing.l) {
        NutritionMetric(value: "1,482", unit: "kcal", spokenUnit: "kilocalories", size: .hero)
        NutritionMetric(value: "82", unit: "g protein", spokenUnit: "grams of protein",
                        size: .large, valueColor: AppColor.protein)
    }
    .padding(Spacing.l)
    .background(AppColor.background)
    .preferredColorScheme(.dark)
}
