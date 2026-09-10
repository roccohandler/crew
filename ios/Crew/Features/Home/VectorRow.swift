// SPEC: A14 (owner-directed 2026-09-09) — Workout · Cardio · Meals, three co-equal slots. The owner named these as the three
// primary logging vectors; F10 measured how far Home was from treating them that way (one filled primary, one outline button
// that moved between states, and one nav-bar glyph that disappeared on the bridge).
//
// Why this is legal under "one primary action per view" (6.1 Five States Law · §1B · S07 · §1D): every slot here is an
// OUTLINE control. The day's workout keeps the single ink-filled primary inside the card above. Position makes them peers;
// weight still says which one the plan is asking for today.
//
// Part III law ① (ink acts) — no slot ever wears ember, even when done: a filled INK dot marks a logged vector. Law ④ keeps
// ember scarce for the flame, the ring and the week strip's done days; three orange dots on Home would spend it.
// A8 — a slot that has nothing to report reads "—", never "0" and never "0/3": a zero is not a verdict.
// 6.3 — each slot is its own ≥ 44 pt target, guaranteed by the frame and contentShape rather than inherited from the label.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct VectorRow: View {
    let slots: VectorSlots
    let onWorkout: () -> Void
    let onCardio: () -> Void
    let onMeal: () -> Void

    // SPEC: 6.7 (`spec:974`, "no truncated CTA labels anywhere") — H009. This was a fixed three-across HStack, and
    // `@ScaledMetric` scales HEIGHT only. On a 375 pt SE: 375 − 32 padding − 24 gaps = 319 / 3 = 106.3 pt per slot,
    // while "Workout" at accessibilityExtraExtraLarge measures ~124 pt. It truncated. `ViewThatFits` drops the row
    // into a stack instead, the way SetRow and UnitConfirmLine already do.
    //
    // C5, deliberately NOT extracted: the two existing ViewThatFits sites have DIFFERENT fallbacks — SetRow reorders
    // its children, UnitConfirmLine flips an axis and drops a Spacer. This is a third shape (equal-width cells → a
    // stack), so it is occurrence ONE of its own kind. Duplicate on the second, extract on the third.
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: EmberTokens.Spacing.space12) { cells }
            VStack(spacing: EmberTokens.Spacing.rowGap) { cells }
        }
    }

    // A17 / H028 — an unlogged slot says "Log", not "—". The em dash is spec-blessed on an INPUT surface (spec:203,
    // "'—' is a complete set forever") but it was never ratified on a STATUS surface, and beside a near-invisible
    // hollow ring it read as the universal idiom for DISABLED — which is exactly what the owner reported. A verb turns
    // three dead cells into three invitations, and it is the same thing that rescues every SecondaryButton in the app:
    // the ink verb, not the 1.26:1 outline, is what says "this is a control".
    @ViewBuilder
    private var cells: some View {
        VectorSlot(title: "Workout", value: slots.workoutDone ? "Done" : "Log", isLogged: slots.workoutDone, action: onWorkout)
        VectorSlot(title: "Cardio", value: slots.cardioMinutes.map { "\($0) min" } ?? "Log", isLogged: slots.cardioMinutes != nil, action: onCardio)
        VectorSlot(title: "Meals", value: slots.meals > 0 ? "\(slots.meals)" : "Log", isLogged: slots.meals > 0, action: onMeal)
    }
}

struct VectorSlot: View {
    let title: String
    let value: String
    let isLogged: Bool
    let action: () -> Void
    @ScaledMetric private var minTarget: CGFloat = CGFloat(SpecConstants.minTouchTargetPt) // 6.5: the slot grows with Dynamic Type

    var body: some View {
        Button(action: action) {
            VStack(spacing: EmberTokens.Spacing.rowGap) {
                Text(title).font(.caption).foregroundStyle(EmberColors.secondaryText)
                HStack(spacing: EmberTokens.Spacing.space4) {
                    // The dot is the redundant encoder: "Done" and "25 min" and "2" are already words, and the shape says
                    // logged-or-not without asking anyone to read them (6.5)
                    Circle()
                        .fill(isLogged ? EmberColors.inkText : Color.clear)
                        // H014: the unlogged ring was `hairline` — 1.26:1 on a card, invisible against the 3:1 gate.
                        .overlay(Circle().stroke(EmberColors.secondaryText, lineWidth: isLogged ? 0 : EmberTokens.Size.hairline))
                        .frame(width: EmberTokens.Spacing.space8, height: EmberTokens.Spacing.space8)
                    Text(value).font(.subheadline.weight(.semibold).monospacedDigit()).foregroundStyle(EmberColors.inkText)
                }
            }
            .frame(maxWidth: .infinity, minHeight: minTarget)
            .padding(.vertical, EmberTokens.Spacing.space8)
            // H028 — the card FILL is gone. With it, the slot was character-for-character the chrome of the read-only
            // `Card` (same fill, same 1 pt hairline), so the eye had no way to tell a control from a container. It now
            // wears exactly what every other secondary control in this app wears: no fill, a hairline outline, an ink
            // label. The outline itself is only 1.26:1 — that is a known app-wide debt with its own repair (a distinct
            // controlOutline token, logged 2026-09-10) — and what actually carries the affordance is the ink verb.
            .overlay(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous).stroke(EmberColors.secondaryButtonOutline, lineWidth: EmberTokens.Size.hairline))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // E20 — "Cardio, 25 min today" / "Cardio, nothing logged today". The visible "Log" is not spoken as a value:
        // the Button trait already tells VoiceOver it is actionable, so repeating the verb would say it twice.
        .accessibilityLabel("\(title), \(isLogged ? "\(value) today" : "nothing logged today")")
    }
}
