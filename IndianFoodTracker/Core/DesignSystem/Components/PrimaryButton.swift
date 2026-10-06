import SwiftUI

/// The main call-to-action button style: solid accent fill, full width.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .foregroundStyle(AppColor.primaryForeground)
            .frame(maxWidth: .infinity, minHeight: Layout.minTapTarget)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                    .fill(AppColor.primary)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
            .contentShape(RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
    }
}

/// A full-width primary button. Usage: PrimaryButton("Add Food") { ... }
struct PrimaryButton: View {
    private let title: String
    private let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

#Preview("Light") {
    VStack(spacing: Spacing.m) {
        PrimaryButton("Add Food") {}
        PrimaryButton("Disabled") {}.disabled(true)
    }
    .padding(Spacing.m)
    .background(AppColor.background)
}

#Preview("Dark") {
    VStack(spacing: Spacing.m) {
        PrimaryButton("Add Food") {}
        PrimaryButton("Disabled") {}.disabled(true)
    }
    .padding(Spacing.m)
    .background(AppColor.background)
    .preferredColorScheme(.dark)
}
