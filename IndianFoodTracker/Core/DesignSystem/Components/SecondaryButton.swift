import SwiftUI

/// The secondary button style: outlined, transparent fill, full width.
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .foregroundStyle(AppColor.accent)
            .frame(maxWidth: .infinity, minHeight: Layout.minTapTarget)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                    .fill(configuration.isPressed ? AppColor.backgroundSecondary : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                    .strokeBorder(AppColor.accent, lineWidth: 1.5)
            )
            .opacity(isEnabled ? 1 : 0.4)
            .contentShape(RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
    }
}

/// A full-width secondary button. Usage: SecondaryButton("Cancel") { ... }
struct SecondaryButton: View {
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
        .buttonStyle(SecondaryButtonStyle())
    }
}

#Preview("Light") {
    VStack(spacing: Spacing.m) {
        SecondaryButton("Cancel") {}
        SecondaryButton("Disabled") {}.disabled(true)
    }
    .padding(Spacing.m)
    .background(AppColor.background)
}

#Preview("Dark") {
    VStack(spacing: Spacing.m) {
        SecondaryButton("Cancel") {}
        SecondaryButton("Disabled") {}.disabled(true)
    }
    .padding(Spacing.m)
    .background(AppColor.background)
    .preferredColorScheme(.dark)
}
