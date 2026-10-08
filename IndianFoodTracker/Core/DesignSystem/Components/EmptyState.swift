import SwiftUI

/// A friendly centered message for screens or sections with nothing in them yet.
struct EmptyState: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: systemImage)
                .font(.system(.largeTitle, design: .rounded, weight: .regular))
                .foregroundStyle(AppColor.accent)
                .accessibilityHidden(true)

            VStack(spacing: Spacing.xs) {
                Text(title)
                    .font(AppTypography.title)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(message)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                PrimaryButton(actionTitle, action: action)
                    .padding(.top, Spacing.xs)
            }
        }
        .frame(maxWidth: 320)
        .padding(Spacing.l)
        .frame(maxWidth: .infinity)
    }
}

#Preview("Light") {
    EmptyState(systemImage: "fork.knife",
               title: "Nothing logged yet",
               message: "Log your first meal to see your day add up here.",
               actionTitle: "Add Food") {}
        .background(AppColor.background)
}

#Preview("Dark") {
    EmptyState(systemImage: "magnifyingglass",
               title: "Food search is coming",
               message: "You'll be able to search Indian foods here soon.")
        .background(AppColor.background)
        .preferredColorScheme(.dark)
}
