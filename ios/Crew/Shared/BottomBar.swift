// SPEC: A19.1 (owner-ratified 2026-09-11) · 6.7 ("bottom CTAs sit above the home indicator, never behind it";
// "reachability holds at Pro Max: primary actions stay bottom-anchored regardless of how much canvas exists above";
// "content that can grow lives in ScrollViews") · 6.3 (≥ 44 pt targets) · Part III law ① (every control is ink).
//
// WHY THIS EXISTS. `safeAreaInset` had ZERO uses in the app. Every screen that claimed a bottom-anchored primary was
// doing one of three things, each wrong in its own way:
//
//   · a `Spacer` inside a `ScrollView` — which collapses to zero the instant content exceeds the viewport, so the
//     anchor holds only while the screen happens to FIT. A18's layout gate measured exactly this on Home: 212 px of
//     slack at 440×956, and 24 px at 375×667 — small there BECAUSE the page already overflowed and the spacer was
//     already gone. At accessibility-XXL it is gone on more screens still.
//   · a `VStack` sibling — the button simply scrolls away with everything else.
//   · an `overlay` plus hand-computed bottom padding (PlanScreen, WorkoutEditorScreen) — which has to guess the home
//     indicator's height and guesses a different number in each file.
//
// `safeAreaInset(edge: .bottom)` is Apple's API for precisely this: the bar sits outside the scrolling content, the
// scroll view insets itself so nothing is ever trapped underneath, and the bar rises above the keyboard rather than
// being covered by it — which is half of A19.2's fix for free.
//
// WHY A MODIFIER IS NOT AN ABSTRACTION HERE (C1–C5). This is the doctrine's own THIRD-OCCURRENCE rule, at the eighth:
// six screens need the same bar and each currently hand-rolls a different wrong version of it. It is one concrete
// `ViewModifier` over one Apple API, with no protocol, no generic, no configuration object and no second
// implementation — extraction into the smallest concrete thing, which is what C5 permits and what C1 asks for.
//
// IT IS CONDITIONAL, AND THAT IS A RULE, NOT AN OPTION. A17.3 ruled that a day asking nothing carries no filled
// primary, and A18.9 gave the all-done card no control at all. A permanent chrome strip at the bottom of every screen
// would manufacture an ask on exactly the states those two decisions cleared — so a screen with no primary calls this
// with nothing, and gets no bar, no divider and no inset.
//
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

extension View {
    // SPEC: A19.1 — the bar. `content` builds the primary (and, where a screen has one, its single secondary beneath).
    func crewBottomBar<Bar: View>(@ViewBuilder _ content: () -> Bar) -> some View {
        modifier(CrewBottomBar(bar: content()))
    }
}

struct CrewBottomBar<Bar: View>: ViewModifier {
    let bar: Bar
    // 6.5 — the bar grows with Dynamic Type. A fixed inset is how a CTA ends up clipped at accessibility-XXL on an SE,
    // which is the device and type combination 6.7 names as non-negotiable.
    @ScaledMetric private var verticalPadding: CGFloat = EmberTokens.Spacing.space12

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                // A18.11 — `controlOutline` (3.32:1 on a card, 3.13:1 on the canvas), never the 1.26:1 hairline family.
                // The bar's top edge separates a control region from scrolling content, which makes it part of the
                // component rather than a seam between two surfaces.
                Rectangle()
                    .fill(EmberColors.controlOutline)
                    .frame(height: EmberTokens.Size.hairline)
                bar
                    .padding(.horizontal, EmberTokens.Spacing.space16)
                    .padding(.vertical, verticalPadding)
            }
            // The canvas, not a card: the bar is the page's own floor, and a second surface colour here would read as
            // a panel floating over the content rather than as the bottom of it.
            .background(EmberColors.canvas)
        }
    }
}
