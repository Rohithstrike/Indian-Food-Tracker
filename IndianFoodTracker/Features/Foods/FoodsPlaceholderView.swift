import SwiftUI

/// PLACEHOLDER for the Foods tab. Becomes real food search in Milestone 10.
struct FoodsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    Text("Foods")
                        .font(AppTypography.largeTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    EmptyState(systemImage: "magnifyingglass",
                               title: "Food search is on its way",
                               message: "Soon you'll find Indian foods here, from idli and dosa to dal and biryani, and log them in a few taps.")
                }
                .padding(.horizontal, Spacing.m)
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.m)
            }
            .background(AppColor.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview("Light") {
    FoodsPlaceholderView()
}

#Preview("Dark") {
    FoodsPlaceholderView().preferredColorScheme(.dark)
}
