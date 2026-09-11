// SPEC: 6.3 (targets ≥ 44×44 pt) — the app's inline text control. Was `SetCountButton` in Features/Session, where it was
// written for "+ set" / "+ warm-up" after the owner reported 2026-09-09 that "the hit boxes feel slightly too small". Its
// original comment diagnosed the bug exactly: they were bare `Button("+ set")`s inside an HStack carrying
// `.frame(minHeight: 44)` — which sizes the ROW, not either button, so a SwiftUI Button's hit rect stayed its label's own
// bounds (~40×18 pt). The fix is a frame AND a `contentShape` on the LABEL itself; `.contentShape` is what makes the padded
// area hittable rather than merely drawn.
//
// It moves to Shared/ because that diagnosis was never applied to the eight other controls with the identical shape —
// Swap · Skip · Open (SessionScreen), Skip · rest length (RestTimerView), React (PostCard), "Same as yesterday"
// (PostComposer) and "Open Settings" (EditProfileScreen) — every one of them a bare text Button relying on an ancestor's
// minHeight. One concrete view now owns the shape so a ninth cannot appear. Ink, never ember (Part III law ①).
//
// `horizontalPadding` exists because the two uses genuinely differ: a standalone control ("+ warm-up", "Open Settings")
// wants breathing room, while a control sharing a cramped row with a wrapping exercise name must take the 44 pt minimum and
// not one point more, or it pushes that name into another line on a 375 pt phone (6.7). Both are the same control; only the
// slack differs. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct TextActionButton: View {
    let title: String
    var font: Font = .subheadline
    var color: Color = EmberColors.inkText
    var horizontalPadding: CGFloat = EmberTokens.Spacing.space12
    var accessibilityLabel: String? = nil
    let action: () -> Void
    @ScaledMetric private var minTarget: CGFloat = CGFloat(SpecConstants.minTouchTargetPt) // 6.5: the target grows with Dynamic Type

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .foregroundStyle(color)
                .padding(.horizontal, horizontalPadding)
                .frame(minWidth: minTarget, minHeight: minTarget)
                .contentShape(Rectangle()) // without this the padding is drawn but not hittable
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel ?? title)
    }
}
