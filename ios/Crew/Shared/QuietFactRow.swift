// SPEC: A28 (d), (f) — the system's quiet fact row (design/focus-card-system.md §8): a 44 pt row set entirely in inkSecondary at
// 15 pt Medium with its numeral rounded. It states a fact and opens a screen on tap; it carries no chevron and never looks like a
// control — its mark is its inkSecondary text (5.84:1, R-083 (2)) and the button trait VoiceOver reads. WRITTEN — UNVERIFIED.

import SwiftUI

struct QuietFactRow: View {
    let text: Text             // built by the caller, so the numeral alone can be rounded ("Macros · " + "2" + " logged")
    let accessibilityLabel: String
    let action: () -> Void
    @ScaledMetric private var minTarget: CGFloat = CGFloat(SpecConstants.minTouchTargetPt) // 6.3: the target grows with the text

    var body: some View {
        Button(action: action) {
            text
                .typeRole(EmberTokens.Typography.secondary)
                .foregroundStyle(EmberColors.inkSecondary)
                .frame(maxWidth: .infinity, minHeight: minTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}
