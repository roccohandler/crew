// SPEC: A28 (a), (d), (f) — the Focus Card: the `card` surface, 28 pt continuous corners, no border; LIGHT lifts it with the
// two-layer ink shadow and DARK with tone alone (design/focus-card-system.md §6 — "gate the shadow on colorScheme rather than
// defining a dark shadow"). Padding is 22 pt on Home and Progress (§5). The legacy `Card` stays for the screens not yet redesigned
// (R-083 (5)) and leaves when the last of them moves (docs/debt.md). WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct FocusCard<Content: View>: View {
    var padding: CGFloat = EmberTokens.Focus.cardPadding
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: EmberTokens.Focus.cardRadius, style: .continuous)
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(EmberColors.card, in: shape)
            .shadow(color: shadowColor(EmberTokens.Elevation.nearOpacity), radius: EmberTokens.Elevation.nearRadius, y: EmberTokens.Elevation.nearY)
            .shadow(color: shadowColor(EmberTokens.Elevation.farOpacity), radius: EmberTokens.Elevation.farRadius, y: EmberTokens.Elevation.farY)
    }

    private func shadowColor(_ opacity: Double) -> Color {
        colorScheme == .light ? EmberColors.ink.opacity(opacity) : .clear
    }
}
