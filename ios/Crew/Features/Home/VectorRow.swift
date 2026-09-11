// SPEC: A14 (owner-directed 2026-09-09) — Workout · Cardio · Meals, three co-equal logging vectors. The owner named
// these as the three primary vectors; F10 measured how far Home was from treating them that way (one filled primary,
// one outline button that moved between states, and one nav-bar glyph that disappeared on the bridge).
//
// A18.5 (owner-directed 2026-09-10) — THE GEOMETRY AND THE GRAMMAR MOVE; A14's content does not. The owner's report
// was "three strange divs at the bottom with workout, cardio, and meals", and there were three separate reasons for it:
//
//   1. THE SHAPE SAID PICKER. Three equal-width bordered cells in a row is, in Apple's own words, a segmented control
//      — "a linear set of two or more segments, each of which functions as a mutually exclusive button", in which
//      "all segments are equal in width". These were three INDEPENDENT buttons wearing the silhouette of a
//      one-of-three choice. Full-width rows carry no such claim.
//   2. THE GRAMMAR SAID READOUT. A caption NOUN over a value is the shape of a stat tile, and the value carried the
//      verb ("Workout" over "Log"). 6.6 requires verb-first control labels; the shipped VoiceOver name was literally
//      "Workout, Done today" on a Button. The verb is now the label, seen and spoken, and the status is the trailing
//      report — which also makes the row read identically whether it is empty or full.
//   3. THE BORDER WAS INVISIBLE. `secondaryButtonOutline` measures 1.26:1 on a card and 1.19:1 on the canvas against
//      6.5's 3:1 gate, so the one mark that says "this is a control" could not be seen. A18.11 gives it its own
//      `controlOutline` token (3.32:1 / 3.13:1), app-wide.
//
// Why three controls here are still legal under "one primary action per view" (6.1 · §1B · S07 · §1D): every row is
// an OUTLINE control, and the day's workout keeps the single ink-filled primary inside the card above. Position makes
// them peers; weight still says which one the plan is asking for today. (Recorded because the repo cites that rule as
// HIG in four places and it is not one: Apple writes "keep the number of prominent buttons to one or two per view".
// It is a Crew rule, and it is a ceiling, not a floor.)
//
// Part III law ① — no row ever wears ember, even when done: a filled INK dot marks a logged vector, and law ④ keeps
// ember scarce for the flame, the ring and the strip. A8 — an unlogged row REPORTS NOTHING rather than reporting a
// zero or an em dash: the verb is the invitation, and H028 already established that "—" reads as disabled.
// 6.3 — each row is its own ≥ 44 pt target, guaranteed by the frame and contentShape rather than inherited.
//
// The `ViewThatFits` fallback is retired with the grid: it existed only because three across truncates ("Workout" at
// accessibilityExtraExtraLarge measures ~124 pt in a 106.3 pt SE cell, H009). A full-width row cannot truncate.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct VectorRow: View {
    let slots: VectorSlots
    let onWorkout: () -> Void
    let onCardio: () -> Void
    let onMeal: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VectorLogRow(verb: "Log workout", status: slots.workoutDone ? "Done" : nil, action: onWorkout)
            rowDivider
            VectorLogRow(verb: "Log cardio", status: slots.cardioMinutes.map { "\($0) min" }, action: onCardio)
            rowDivider
            VectorLogRow(verb: "Log a meal", status: slots.meals > 0 ? "\(slots.meals)" : nil, action: onMeal)
        }
        // One boundary around the group, not three: the rows are a set of peers, and three separate outlines would
        // put two hairlines between every pair. `controlOutline` (A18.11), never the surface hairline.
        .overlay(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous).stroke(EmberColors.controlOutline, lineWidth: EmberTokens.Size.hairline))
        .clipShape(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous))
    }

    // A divider BETWEEN two surfaces is not a control, so this one keeps `hairline` — the distinction A18.11 is built
    // on, applied here so the file cannot be read as an exception to it.
    private var rowDivider: some View {
        Rectangle().fill(EmberColors.hairline).frame(height: EmberTokens.Size.hairline)
    }
}

struct VectorLogRow: View {
    let verb: String
    let status: String?  // nil = nothing logged today; A8 — the row reports nothing rather than reporting a zero
    let action: () -> Void
    @ScaledMetric private var minTarget: CGFloat = CGFloat(SpecConstants.minTouchTargetPt) // 6.5: the row grows with Dynamic Type

    var body: some View {
        Button(action: action) {
            HStack(spacing: EmberTokens.Spacing.space8) {
                Text(verb)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(EmberColors.inkText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true) // 6.7: at XXL it wraps inside its own row; it cannot truncate
                Spacer(minLength: EmberTokens.Spacing.space8)
                if let status {
                    // The dot is the redundant encoder (6.5 / WCAG 1.4.1): the shape says logged without anyone
                    // reading the number. Ink, never ember — law ① and law ④.
                    Circle()
                        .fill(EmberColors.inkText)
                        .frame(width: EmberTokens.Spacing.space8, height: EmberTokens.Spacing.space8)
                    Text(status)
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(EmberColors.inkText)
                }
            }
            .frame(maxWidth: .infinity, minHeight: minTarget, alignment: .leading)
            .padding(.horizontal, EmberTokens.Spacing.space16)
            .padding(.vertical, EmberTokens.Spacing.space12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // E20 — the Button trait already says it is actionable, so the verb is not repeated as a value: "Log cardio,
        // 25 min today" / "Log cardio, nothing logged today".
        .accessibilityLabel("\(verb), \(status.map { "\($0) today" } ?? "nothing logged today")")
    }
}
