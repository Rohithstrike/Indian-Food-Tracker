import SwiftUI

/// A section title with optional trailing text, e.g. "Breakfast" ... "380 kcal".
struct SectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Spacing.s)
            if let trailing {
                Text(trailing)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .monospacedDigit()
            }
        }
    }
}

#Preview("Light") {
    VStack(spacing: Spacing.m) {
        SectionHeader(title: "Breakfast", trailing: "380 kcal")
        SectionHeader(title: "Recent foods")
    }
    .padding(Spacing.m)
    .background(AppColor.background)
}

#Preview("Dark") {
    VStack(spacing: Spacing.m) {
        SectionHeader(title: "Breakfast", trailing: "380 kcal")
        SectionHeader(title: "Recent foods")
    }
    .padding(Spacing.m)
    .background(AppColor.background)
    .preferredColorScheme(.dark)
}
