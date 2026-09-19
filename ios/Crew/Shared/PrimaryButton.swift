// SPEC: Part III law ① — ink acts: primary buttons are #211D19 fill with #FAF8F5 label (dark: inverted ink), never
// orange; 6.3 targets ≥ 44 pt; 6.6 verb-first labels. WRITTEN — UNVERIFIED (needs Mac).
//
// A18.11 (2026-09-10) — the secondary button's boundary moves from `secondaryButtonOutline` (#E9E4DD, 1.26:1 on a
// card and 1.19:1 on the canvas) to `controlOutline` (3.32:1 / 3.13:1). 6.5's non-text gate governs "the visual
// information required to identify user interface components", and the outline IS that information on a control
// with no fill: at 1.26:1 the thing saying "this is a button" was invisible, which is exactly what the owner
// reported about Home's three log rows. This is app-wide: every SecondaryButton in Crew draws through this line.

import SwiftUI

// A28 (f) (2026-09-19) — the system's primary button: a filled ink CAPSULE, the onInk label at 17 pt Bold, 58 pt tall (56 on Home),
// at most one per screen. App-wide, because the shape is the component's and every screen already calls this one view; the height
// is a MINIMUM (R-083 (20)): at accessibility sizes the label wraps and the capsule grows, it never truncates (6.7).
struct PrimaryButton: View {
    let title: String
    var isLoading = false
    var height: CGFloat = EmberTokens.Focus.primaryHeight
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .typeRole(EmberTokens.Typography.primaryLabel)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, EmberTokens.Focus.cardPadding)
                    .opacity(isLoading ? 0 : 1)
                if isLoading { ProgressView().tint(EmberColors.onInk) }
            }
            .frame(maxWidth: .infinity, minHeight: height)
            .foregroundStyle(EmberColors.onInk)
            .background(EmberColors.ink, in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(title)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                .foregroundStyle(EmberColors.secondaryButtonLabel)
                .overlay(RoundedRectangle(cornerRadius: EmberTokens.Spacing.space16, style: .continuous).stroke(EmberColors.controlOutline, lineWidth: EmberTokens.Size.hairline))
        }
        .buttonStyle(.plain)
    }
}
