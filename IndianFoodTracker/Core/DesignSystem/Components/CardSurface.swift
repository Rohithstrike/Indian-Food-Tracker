import SwiftUI

/// Gives any content a rounded card background with subtle contrast.
struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                    .fill(AppColor.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                    .strokeBorder(AppColor.divider, lineWidth: 1)
            )
    }
}

extension View {
    /// Wraps the view in a card. Usage: Text("Hello").cardSurface()
    func cardSurface() -> some View {
        modifier(CardSurface())
    }
}

#Preview("Light") {
    VStack(spacing: Spacing.m) {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("3 Idlis").font(AppTypography.headline)
            Text("Sample card content").font(AppTypography.callout)
                .foregroundStyle(AppColor.textSecondary)
        }
        .cardSurface()
    }
    .padding(Spacing.m)
    .background(AppColor.background)
}

#Preview("Dark") {
    VStack(spacing: Spacing.m) {
        Text("Sample card").font(AppTypography.headline).cardSurface()
    }
    .padding(Spacing.m)
    .background(AppColor.background)
    .preferredColorScheme(.dark)
}
