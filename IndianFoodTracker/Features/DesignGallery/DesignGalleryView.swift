import SwiftUI

/// TEMPORARY reference screen that shows every design token and component.
/// It gets replaced by real navigation in Milestone 5.
struct DesignGalleryView: View {
    private let swatches: [(name: String, color: Color)] = [
        ("background", AppColor.background),
        ("backgroundSecondary", AppColor.backgroundSecondary),
        ("surface", AppColor.surface),
        ("surfaceElevated", AppColor.surfaceElevated),
        ("primary", AppColor.primary),
        ("primaryForeground", AppColor.primaryForeground),
        ("accent", AppColor.accent),
        ("textPrimary", AppColor.textPrimary),
        ("textSecondary", AppColor.textSecondary),
        ("textTertiary", AppColor.textTertiary),
        ("divider", AppColor.divider),
        ("success", AppColor.success),
        ("warning", AppColor.warning),
        ("error", AppColor.error),
        ("protein", AppColor.protein),
        ("carbs", AppColor.carbs),
        ("fat", AppColor.fat)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                Text("Design Gallery")
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                colorsSection
                typographySection
                caloriesSection
                buttonsSection
                headerAndCardSection
            }
            .padding(Spacing.m)
        }
        .background(AppColor.background.ignoresSafeArea())
    }

    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "Colors")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: Spacing.s)],
                      spacing: Spacing.s) {
                ForEach(swatches, id: \.name) { swatch in
                    HStack(spacing: Spacing.xs) {
                        RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                            .fill(swatch.color)
                            .frame(width: 36, height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                                    .strokeBorder(AppColor.divider, lineWidth: 1)
                            )
                            .accessibilityHidden(true)
                        Text(swatch.name)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            SectionHeader(title: "Typography")
            Group {
                Text("Large Title").font(AppTypography.largeTitle)
                Text("Title").font(AppTypography.title)
                Text("Headline").font(AppTypography.headline)
                Text("Body text for normal reading").font(AppTypography.body)
                Text("Callout text").font(AppTypography.callout)
                Text("Caption text").font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                Text("Tertiary note text").font(AppTypography.caption)
                    .foregroundStyle(AppColor.textTertiary)
            }
            .foregroundStyle(AppColor.textPrimary)
        }
    }

    private var caloriesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "Today's calories", trailing: "1,482 / 2,100")
            VStack(spacing: Spacing.l) {
                NutritionMetric(value: "1,482", unit: "kcal",
                                spokenUnit: "kilocalories", size: .hero)
                HStack(alignment: .top) {
                    NutritionMetric(value: "82", unit: "g protein",
                                    spokenUnit: "grams of protein",
                                    size: .large, valueColor: AppColor.protein)
                    Spacer(minLength: Spacing.xs)
                    NutritionMetric(value: "165", unit: "g carbs",
                                    spokenUnit: "grams of carbohydrates",
                                    size: .large, valueColor: AppColor.carbs)
                    Spacer(minLength: Spacing.xs)
                    NutritionMetric(value: "48", unit: "g fat",
                                    spokenUnit: "grams of fat",
                                    size: .large, valueColor: AppColor.fat)
                }
            }
            .frame(maxWidth: .infinity)
            .cardSurface()
        }
    }

    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "Buttons")
            PrimaryButton("Add Food") {}
            SecondaryButton("Cancel") {}
            PrimaryButton("Disabled") {}.disabled(true)
        }
    }

    private var headerAndCardSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "Breakfast", trailing: "380 kcal")
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("3 Idlis")
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColor.textPrimary)
                Text("Sample card (demo only, not real nutrition data)")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .cardSurface()
        }
    }
}

#Preview("Light") {
    DesignGalleryView()
}

#Preview("Dark") {
    DesignGalleryView().preferredColorScheme(.dark)
}
