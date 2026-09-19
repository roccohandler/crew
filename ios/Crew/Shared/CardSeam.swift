// SPEC: A28 (f) — the seam between two rows of one card (design/focus-card-system.md §8): `hairlineOnCard`, one hairline tall, inset
// like the rows it separates. Written inline eighteen times before the Settings destinations left the platform's List (R-091); new
// code reads it here (C5: a plain function, not a component). WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

func cardSeam(inset: CGFloat = EmberTokens.Focus.setCardInset) -> some View {
    Rectangle().fill(EmberColors.hairlineOnCard).frame(height: EmberTokens.Size.hairline).padding(.leading, inset)
}
