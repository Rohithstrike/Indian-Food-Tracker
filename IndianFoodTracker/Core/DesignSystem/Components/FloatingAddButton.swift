import SwiftUI

/// The floating "Add Food" capsule. Uses Apple's glass material, with a solid
/// fallback when Reduce Transparency is on.
struct FloatingAddButton: View {
    let action: () -> Void

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "plus")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppColor.accent)
                Text("Add Food")
                    .font(AppTypography.button)
                    .foregroundStyle(AppColor.textPrimary)
            }
            .padding(.horizontal, Spacing.l)
            .frame(minHeight: Layout.minTapTarget + Spacing.xxs)
            .modifier(FloatingSurface(reduceTransparency: reduceTransparency))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add food")
        .accessibilityHint("Choose a meal to add food to")
    }
}

/// Glass normally; solid surface with a border when transparency is reduced.
private struct FloatingSurface: ViewModifier {
    let reduceTransparency: Bool

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(Capsule().fill(AppColor.surfaceElevated))
                .overlay(Capsule().strokeBorder(AppColor.divider, lineWidth: 1))
        } else {
            content
                .glassEffect(.regular.interactive(), in: Capsule())
        }
    }
}

#Preview("Light") {
    ZStack(alignment: .bottom) {
        AppColor.background.ignoresSafeArea()
        VStack(spacing: 0) {
            ForEach(0..<8) { _ in
                Rectangle().fill(AppColor.backgroundSecondary).frame(height: 40)
                Rectangle().fill(AppColor.surface).frame(height: 40)
            }
        }
        FloatingAddButton {}.padding(.bottom, Spacing.l)
    }
}

#Preview("Dark") {
    ZStack(alignment: .bottom) {
        AppColor.background.ignoresSafeArea()
        FloatingAddButton {}.padding(.bottom, Spacing.l)
    }
    .preferredColorScheme(.dark)
}
