import SwiftUI

/// The main screen: greeting, calorie hero, seven meal sections, and a floating Add Food button.
struct TodayView: View {
    @State private var viewModel: TodayViewModel

    /// Called when the user wants to add food. `nil` means "no meal chosen yet".
    private let onAddFood: (MealType?) -> Void

    init(viewModel: TodayViewModel = TodayViewModel(),
         onAddFood: @escaping (MealType?) -> Void = { _ in }) {
        _viewModel = State(initialValue: viewModel)
        self.onAddFood = onAddFood
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    header

                    CalorieHeroCard(calories: viewModel.totalCalories,
                                    target: viewModel.calorieTarget,
                                    protein: viewModel.totalProtein,
                                    carbs: viewModel.totalCarbs,
                                    fat: viewModel.totalFat)

                    ForEach(MealType.allCases) { meal in
                        MealSectionCard(meal: meal, items: viewModel.items(for: meal)) {
                            onAddFood(meal)
                        }
                    }
                }
                .padding(.horizontal, Spacing.m)
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.m)
            }
            .background(AppColor.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                FloatingAddButton { onAddFood(nil) }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(viewModel.greeting)
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(viewModel.dateText)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer(minLength: Spacing.s)
            #if DEBUG
            debugMenu
            #endif
        }
    }

    #if DEBUG
    /// Debug builds only. Lets us judge the populated design with clearly fake data.
    private var debugMenu: some View {
        Menu {
            Button("Load demo data") { viewModel.loadDemoData() }
            Button("Clear data", role: .destructive) { viewModel.clearAll() }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(.title2, design: .rounded))
                .foregroundStyle(AppColor.accent)
                .frame(minWidth: Layout.minTapTarget, minHeight: Layout.minTapTarget)
        }
        .accessibilityLabel("Debug menu")
    }
    #endif
}

#Preview("Empty, light") {
    TodayView()
}

#if DEBUG
#Preview("Demo data, dark") {
    TodayView(viewModel: .demo)
        .preferredColorScheme(.dark)
}

#Preview("Demo data, large text") {
    TodayView(viewModel: .demo)
        .dynamicTypeSize(.accessibility2)
}
#endif



