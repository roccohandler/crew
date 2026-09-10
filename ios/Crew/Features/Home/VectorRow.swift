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

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space12) {
            VectorSlot(title: "Workout", value: slots.workoutDone ? "Done" : "—", isLogged: slots.workoutDone, action: onWorkout)
            VectorSlot(title: "Cardio", value: slots.cardioMinutes.map { "\($0) min" } ?? "—", isLogged: slots.cardioMinutes != nil, action: onCardio)
            VectorSlot(title: "Meals", value: slots.meals > 0 ? "\(slots.meals)" : "—", isLogged: slots.meals > 0, action: onMeal)
        }
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
                        .overlay(Circle().stroke(EmberColors.hairline, lineWidth: isLogged ? 0 : EmberTokens.Size.hairline))
                        .frame(width: EmberTokens.Spacing.space8, height: EmberTokens.Spacing.space8)
                    Text(value).font(.subheadline.weight(.semibold).monospacedDigit()).foregroundStyle(EmberColors.inkText)
                }
            }
            .frame(maxWidth: .infinity, minHeight: minTarget)
            .padding(.vertical, EmberTokens.Spacing.space8)
            .background(EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous).stroke(EmberColors.hairline, lineWidth: EmberTokens.Size.hairline))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // E20 — "Cardio, 25 min today" / "Cardio, nothing logged today"; the em dash is not a word, so it is never spoken
        .accessibilityLabel("\(title), \(isLogged ? "\(value) today" : "nothing logged today")")
    }
}
