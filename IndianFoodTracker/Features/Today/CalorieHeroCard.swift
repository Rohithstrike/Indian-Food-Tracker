import SwiftUI

/// The hero of the Today screen: calorie ring, remaining calories, and macro totals.
struct CalorieHeroCard: View {
    let calories: Int
    let target: Int
    let protein: Int
    let carbs: Int
    let fat: Int

    private var remaining: Int { target - calories }
    private var isOver: Bool { remaining < 0 }
    private var progress: Double { target > 0 ? Double(calories) / Double(target) : 0 }

    var body: some View {
        VStack(spacing: Spacing.l) {
            VStack(spacing: Spacing.s) {
                CalorieRing(progress: progress) {
                    NutritionMetric(value: calories.formatted(), unit: "kcal",
                                    spokenUnit: "kilocalories", size: .hero)
                }
                summary
            }
            .padding(.top, Spacing.xs)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(spokenSummary)

            Rectangle()
                .fill(AppColor.divider)
                .frame(height: 1)
                .accessibilityHidden(true)

            macroRow
        }
        .frame(maxWidth: .infinity)
        .cardSurface()
    }

    // MARK: - Summary under the ring

    private var summary: some View {
        VStack(spacing: Spacing.xxs) {
            if isOver {
                Text("\(abs(remaining).formatted()) kcal over target")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.warning)
            } else {
                Text("\(remaining.formatted()) kcal remaining")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.textPrimary)
            }
            Text(calories == 0 ? "Log your first meal to begin"
                               : "Target \(target.formatted()) kcal")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .multilineTextAlignment(.center)
    }

    private var spokenSummary: String {
        let status = isOver
            ? "\(abs(remaining).formatted()) kilocalories over target"
            : "\(remaining.formatted()) kilocalories remaining"
        return "\(calories.formatted()) of \(target.formatted()) kilocalories. \(status)"
    }

    // MARK: - Macros

    /// Three columns normally; stacked rows when text is too large to fit side by side.
    private var macroRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: Spacing.xs) {
                macroColumns(asRows: false)
            }
            VStack(spacing: Spacing.s) {
                macroColumns(asRows: true)
            }
        }
    }

    @ViewBuilder
    private func macroColumns(asRows: Bool) -> some View {
        MacroColumn(name: "Protein", spokenName: "protein", value: protein,
                    color: AppColor.protein, asRow: asRows)
        MacroColumn(name: "Carbs", spokenName: "carbohydrates", value: carbs,
                    color: AppColor.carbs, asRow: asRows)
        MacroColumn(name: "Fat", spokenName: "fat", value: fat,
                    color: AppColor.fat, asRow: asRows)
    }
}

/// One macro: a small color marker, a text label, and the gram amount.
/// The label is always text, so meaning never depends on color alone.
private struct MacroColumn: View {
    let name: String
    let spokenName: String
    let value: Int
    let color: Color
    let asRow: Bool

    private var amount: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
            Text(value.formatted())
                .font(AppTypography.numberLarge)
                .foregroundStyle(color)
                .monospacedDigit()
            Text("g")
                .font(AppTypography.unitLabel)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    var body: some View {
        Group {
            if asRow {
                HStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                        .accessibilityHidden(true)
                    Text(name)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColor.textSecondary)
                    Spacer(minLength: Spacing.s)
                    amount
                }
            } else {
                VStack(spacing: Spacing.xxs) {
                    Capsule()
                        .fill(color)
                        .frame(width: 24, height: 4)
                        .accessibilityHidden(true)
                    Text(name)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColor.textSecondary)
                    amount
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value.formatted()) grams of \(spokenName)")
    }
}

#Preview("Empty, light") {
    CalorieHeroCard(calories: 0, target: 2000, protein: 0, carbs: 0, fat: 0)
        .padding(Spacing.m)
        .background(AppColor.background)
}

#Preview("Populated, dark") {
    CalorieHeroCard(calories: 1420, target: 2000, protein: 59, carbs: 180, fat: 48)
        .padding(Spacing.m)
        .background(AppColor.background)
        .preferredColorScheme(.dark)
}

#Preview("Over target") {
    CalorieHeroCard(calories: 2240, target: 2000, protein: 90, carbs: 260, fat: 80)
        .padding(Spacing.m)
        .background(AppColor.background)
}

#Preview("Large text") {
    CalorieHeroCard(calories: 1420, target: 2000, protein: 59, carbs: 180, fat: 48)
        .padding(Spacing.m)
        .background(AppColor.background)
        .dynamicTypeSize(.accessibility2)
}
