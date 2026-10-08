import SwiftUI

/// One meal on the Today screen: a header, then either a tappable empty row
/// or a card listing the foods logged for that meal.
struct MealSectionCard: View {
    let meal: MealType
    let items: [TodayItem]
    let onAdd: () -> Void

    @ScaledMetric(relativeTo: .body) private var badgeSize: CGFloat = 36

    private var totalCalories: Int { items.reduce(0) { $0 + $1.calories } }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: meal.displayName,
                          trailing: items.isEmpty ? nil : "\(totalCalories.formatted()) kcal")
            if items.isEmpty {
                emptyRow
            } else {
                filledCard
            }
        }
    }

    // MARK: - Empty

    private var emptyRow: some View {
        Button(action: onAdd) {
            HStack(spacing: Spacing.s) {
                Image(systemName: meal.systemImage)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(AppColor.accent)
                    .frame(width: badgeSize, height: badgeSize)
                    .background(Circle().fill(AppColor.backgroundSecondary))
                    .accessibilityHidden(true)
                Text(meal.addPrompt)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer(minLength: Spacing.s)
                Image(systemName: "plus")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppColor.accent)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: Layout.minTapTarget)
            .cardSurface()
            .contentShape(RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(meal.addPrompt)
    }

    // MARK: - Filled

    private var filledCard: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                itemRow(item)
                Rectangle()
                    .fill(AppColor.divider)
                    .frame(height: 1)
                    .accessibilityHidden(true)
            }
            Button(action: onAdd) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "plus")
                        .accessibilityHidden(true)
                    Text("Add food")
                }
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundStyle(AppColor.accent)
                .frame(maxWidth: .infinity, minHeight: Layout.minTapTarget, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add food to \(meal.displayName)")
        }
        .cardSurface()
    }

    private func itemRow(_ item: TodayItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.name)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)
                Text(item.detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer(minLength: Spacing.s)
            Text("\(item.calories.formatted()) kcal")
                .font(AppTypography.callout)
                .foregroundStyle(AppColor.textPrimary)
                .monospacedDigit()
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.name), \(item.detail), \(item.calories.formatted()) kilocalories")
    }
}

#Preview("Empty, light") {
    VStack(spacing: Spacing.l) {
        MealSectionCard(meal: .breakfast, items: []) {}
        MealSectionCard(meal: .snack, items: []) {}
    }
    .padding(Spacing.m)
    .background(AppColor.background)
}

#Preview("Filled, dark") {
    MealSectionCard(meal: .lunch, items: [
        TodayItem(name: "DEMO food 4", detail: "Sample values, not real data",
                  calories: 450, protein: 18, carbs: 60, fat: 14),
        TodayItem(name: "DEMO food 5", detail: "Sample values, not real data",
                  calories: 120, protein: 4, carbs: 18, fat: 3)
    ]) {}
    .padding(Spacing.m)
    .background(AppColor.background)
    .preferredColorScheme(.dark)
}
