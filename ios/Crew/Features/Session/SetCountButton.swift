// SPEC: 6.3 (targets ≥ 44×44 pt) — the "+ set" and "+ warm-up" controls under an exercise's rows. Owner-reported
// 2026-09-09: "the hit boxes feel slightly too small". They were bare `Button("+ set")`s inside an HStack carrying
// `.frame(minHeight: 44)` — which sizes the ROW, not either button: a SwiftUI Button's hit rect is its label's own
// bounds, so the real targets measured about 40×18 pt and 76×18 pt, under half the required height. The fix is a frame
// AND a contentShape on the label itself; `.contentShape` is what makes the padded area hittable rather than just drawn.
// Ink, never ember (Part III law ①). Its own file for the C9 200-line cap on SessionScreen. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct SetCountButton: View {
    let title: String
    let accessibilityLabel: String
    let action: () -> Void
    @ScaledMetric private var minTarget: CGFloat = CGFloat(SpecConstants.minTouchTargetPt) // 6.5: the target grows with Dynamic Type

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(EmberColors.inkText)
                .padding(.horizontal, EmberTokens.Spacing.space12)
                .frame(minWidth: minTarget, minHeight: minTarget)
                .contentShape(Rectangle()) // without this the padding is drawn but not hittable
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
