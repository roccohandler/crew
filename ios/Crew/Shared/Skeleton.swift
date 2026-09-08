// SPEC: 6.1 Loading — skeleton within 100 ms, mirroring the final layout (zero layout shift); 1A — the launch frame IS
// Home's skeleton. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct SkeletonBlock: View {
    var height: CGFloat = EmberTokens.Spacing.space24

    var body: some View {
        RoundedRectangle(cornerRadius: EmberTokens.Spacing.space8, style: .continuous)
            .fill(EmberColors.hairline)
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
            .accessibilityHidden(true)
    }
}

// Home's skeleton: today card, ring row, crew strip — the same three blocks Home renders when loaded (S07)
struct HomeSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            SkeletonBlock(height: EmberTokens.Spacing.space32)
            SkeletonBlock(height: EmberTokens.Size.skeletonHero)
            SkeletonBlock(height: EmberTokens.Size.skeletonRow)
            Spacer()
        }
        .padding(EmberTokens.Spacing.space16)
        .background(EmberColors.canvas)
    }
}

struct ListSkeleton: View {
    var rows = SpecConstants.skeletonPlaceholderRows

    var body: some View {
        VStack(spacing: EmberTokens.Spacing.space12) {
            ForEach(0..<rows, id: \.self) { _ in SkeletonBlock(height: EmberTokens.Size.skeletonRow) }
            Spacer()
        }
        .padding(EmberTokens.Spacing.space16)
    }
}
