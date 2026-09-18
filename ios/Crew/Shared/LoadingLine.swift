// SPEC: 6.1 Loading, as amended 2026-09-18 (owner-directed, "launch: real UI first"): NO full-screen skeleton anywhere. A screen
// draws its real chrome at once from what the phone already holds, and the one thing still arriving says so IN PLACE — one line
// and a small indeterminate indicator (the HIG's activity indicator for a short, unknown wait). Replaces HomeSkeleton / ListSkeleton
// / SkeletonBlock (deleted). Ink and secondary ink only (Part III law ①). WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct LoadingLine: View {
    let line: String

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space8) {
            ProgressView().controlSize(.small).tint(EmberColors.secondaryText)
            Text(line).font(.footnote).foregroundStyle(EmberColors.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt), alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}
