import SwiftUI

/// Describes a request to add food. `meal` is nil when the user used the general Add Food button.
struct AddFoodRequest: Identifiable {
    let id = UUID()
    let meal: MealType?
}

/// PLACEHOLDER sheet. It proves the flow (tap, sheet, dismiss) and lets the user pick a meal.
/// Real food search is added in Milestone 10.
struct AddFoodSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedMeal: MealType?
    @ScaledMetric(relativeTo: .body) private var badgeSize: CGFloat = 36

    init(request: AddFoodRequest) {
        _selectedMeal = State(initialValue: request.meal)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        SectionHeader(title: "Choose a meal")
                        VStack(spacing: Spacing.xs) {
                            ForEach(MealType.allCases) { meal in
                                mealRow(meal)
                            }
                        }
                    }

                    EmptyState(systemImage: "magnifyingglass",
                               title: "Food search is on its way",
                               message: "Soon you'll search Indian foods here and log them to the meal you've chosen.")
                }
                .padding(.horizontal, Spacing.m)
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.m)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .tint(AppColor.accent)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func mealRow(_ meal: MealType) -> some View {
        let isSelected = selectedMeal == meal
        return Button {
            selectedMeal = meal
        } label: {
            HStack(spacing: Spacing.s) {
                Image(systemName: meal.systemImage)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(AppColor.accent)
                    .frame(width: badgeSize, height: badgeSize)
                    .background(Circle().fill(AppColor.backgroundSecondary))
                    .accessibilityHidden(true)
                Text(meal.displayName)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)
                Spacer(minLength: Spacing.s)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(AppColor.primary)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: Layout.minTapTarget)
            .cardSurface()
            .overlay(
                RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                    .strokeBorder(AppColor.primary, lineWidth: 2)
                    .opacity(isSelected ? 1 : 0)
            )
            .contentShape(RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: selectedMeal)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(meal.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Meal preselected, light") {
    Color.clear.sheet(isPresented: .constant(true)) {
        AddFoodSheet(request: AddFoodRequest(meal: .lunch))
    }
}

#Preview("No meal, dark") {
    Color.clear.sheet(isPresented: .constant(true)) {
        AddFoodSheet(request: AddFoodRequest(meal: nil))
            .preferredColorScheme(.dark)
    }
}
