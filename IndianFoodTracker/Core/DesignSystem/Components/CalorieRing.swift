import SwiftUI

/// A circular progress ring with room for content (the calorie number) in the middle.
/// `progress` is 0...1 of the daily target. Values above 1 fill the ring and turn it to the warning color.
struct CalorieRing<Content: View>: View {
    private let progress: Double
    private let lineWidth: CGFloat
    private let content: Content

    @ScaledMetric(relativeTo: .largeTitle) private var scaledDiameter: CGFloat = 232
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownProgress: Double = 0

    init(progress: Double, lineWidth: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.content = content()
    }

    private var clamped: Double { min(max(progress, 0), 1) }
    private var isOverTarget: Bool { progress > 1 }

    /// Grows with Dynamic Type, but never beyond 300 pt.
    private var diameter: CGFloat { min(scaledDiameter, 300) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColor.divider, lineWidth: lineWidth)
                .accessibilityHidden(true)

            if shownProgress > 0 {
                Circle()
                    .trim(from: 0, to: shownProgress)
                    .stroke(isOverTarget ? AppColor.warning : AppColor.primary,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .accessibilityHidden(true)
            }

            content
                .padding(lineWidth + Spacing.s)
        }
        .frame(width: diameter, height: diameter)
        .padding(lineWidth / 2)
        .onAppear { update(to: clamped) }
        .onChange(of: clamped) { _, newValue in update(to: newValue) }
    }

    private func update(to value: Double) {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.9)) {
            shownProgress = value
        }
    }
}

#Preview("Light") {
    VStack(spacing: Spacing.l) {
        CalorieRing(progress: 0.74) {
            NutritionMetric(value: "1,482", unit: "kcal", spokenUnit: "kilocalories", size: .hero)
        }
        CalorieRing(progress: 0) {
            NutritionMetric(value: "0", unit: "kcal", spokenUnit: "kilocalories", size: .hero)
        }
    }
    .padding(Spacing.m)
    .background(AppColor.background)
}

#Preview("Dark, over target") {
    CalorieRing(progress: 1.12) {
        NutritionMetric(value: "2,240", unit: "kcal", spokenUnit: "kilocalories", size: .hero)
    }
    .padding(Spacing.m)
    .background(AppColor.background)
    .preferredColorScheme(.dark)
}
