import SwiftUI

/// PLACEHOLDER Settings tab. Real settings (calorie target, units) arrive in Milestone 17.
struct SettingsView: View {
    @ScaledMetric(relativeTo: .body) private var badgeSize: CGFloat = 36

    private var versionText: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    Text("Settings")
                        .font(AppTypography.largeTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    aboutSection

                    #if DEBUG
                    developerSection
                    #endif
                }
                .padding(.horizontal, Spacing.m)
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.m)
            }
            .background(AppColor.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "About")
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Version")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textPrimary)
                    Spacer(minLength: Spacing.s)
                    Text(versionText)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                        .monospacedDigit()
                }
                .frame(minHeight: Layout.minTapTarget)

                Rectangle()
                    .fill(AppColor.divider)
                    .frame(height: 1)
                    .accessibilityHidden(true)

                Text("Indian Food Tracker is free to use, with no account, no ads and no tracking.")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.top, Spacing.s)
            }
            .cardSurface()
        }
    }

    #if DEBUG
    /// Debug builds only. Keeps the Design Gallery reachable while we build the real app.
    private var developerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            SectionHeader(title: "Developer")
            NavigationLink {
                DesignGalleryView()
                    .toolbar(.visible, for: .navigationBar)
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack(spacing: Spacing.s) {
                    Image(systemName: "paintpalette")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(AppColor.accent)
                        .frame(width: badgeSize, height: badgeSize)
                        .background(Circle().fill(AppColor.backgroundSecondary))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Design Gallery")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textPrimary)
                        Text("Debug builds only")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    Spacer(minLength: Spacing.s)
                    Image(systemName: "chevron.right")
                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppColor.textTertiary)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: Layout.minTapTarget)
                .cardSurface()
                .contentShape(RoundedRectangle(cornerRadius: Radius.large, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }
    #endif
}

#Preview("Light") {
    SettingsView()
}

#Preview("Dark") {
    SettingsView().preferredColorScheme(.dark)
}
