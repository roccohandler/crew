// SPEC: A28 (f) — the system's row button (design/focus-card-system.md §8): a full-width list row, name, optional value, chevron,
// 56 pt minimum, inside a card at the set card's inset. Extracted at its third occurrence (C5) — Progress's Charts and Journal
// rows and Plan's Change days and Rebuild my week share it; the "+" sheet's rows (a test identifier) and the whole-workout sheet's
// (a segment row) draw their own. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct RowButton: View {
    let title: String
    var value: String? = nil
    let action: () -> Void
    @ScaledMetric private var minHeight: CGFloat = EmberTokens.Focus.rowButton // grows with Dynamic Type (6.5)

    var body: some View {
        Button(action: action) {
            HStack(spacing: EmberTokens.Spacing.space12) {
                Text(title).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: EmberTokens.Spacing.space8)
                if let value { Text(numerals: value).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary) }
                Image(systemName: "chevron.right").foregroundStyle(EmberColors.chevron)
            }
            .padding(.horizontal, EmberTokens.Focus.setCardInset)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(value.map { "\(title), \($0)" } ?? title)
    }
}
