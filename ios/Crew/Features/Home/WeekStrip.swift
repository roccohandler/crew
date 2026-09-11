// SPEC: A14 (owner-directed 2026-09-09) · A17.1 / A17.4 (2026-09-10) — the seven-day strip and the one ink sentence
// under it.
//
// HomeModel has always computed `weeklyRing: [DayRingState]` (done · missed · rest · today · upcoming) and passed it
// straight into WeeklyRing(days:), WHICH NEVER READ THE PARAMETER (F12). So the user saw "2/4" and one continuous arc
// and could not tell WHICH two days they hit. A14 rendered the marks. A17 adds the sentence, because marks alone were
// still unreadable: the owner's report was "I don't know what the colors are for", and the answer is to say so in
// words, in place, rather than in a legend the eye has to travel to and back from.
//
// Part III law ④ — a done day is the one place ember belongs here (progress IS the message); everything else is ink or
// the secondary gray, and the strip is never a control: it reports, it does not navigate (there is nothing to navigate
// TO — tapping a past day is Progress's job, and Home must not grow a second destination for it).
// 6.5: the marks carry a shape as well as a colour AND clear the 3:1 non-text ratio (H014) — the A14 pass answered
// only the first of those two and certified the strip on it.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct WeekStrip: View {
    let days: [DayRingState]
    private let initials = ["M", "T", "W", "T", "F", "S", "S"] // ISO order, Monday weeks (Appendix A policy)

    // One pass, two forms — the eye reads `short`, VoiceOver reads `spoken`. They come from the same function so the
    // strip can never again say one thing on screen and another aloud.
    private var lines: WeekSummaryLines { WeekSummary.weekSummary(days.prefix(TimeUnits.daysPerWeek).map(\.rawValue)) }

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.rowGap) {
            // H005: the alignment was implicit (.center) while the web twin used `align-items: flex-end`, so the
            // caption row ragged in opposite directions and no screenshot comparison could ever agree. Every mark now
            // sits in the same box whatever its own size, so a 4 pt tick and a 12 pt ring share one centre line.
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(days.prefix(TimeUnits.daysPerWeek).enumerated()), id: \.offset) { index, state in
                    VStack(spacing: EmberTokens.Spacing.rowGap) {
                        Text(initials[index]).font(.caption2).foregroundStyle(EmberColors.secondaryText)
                        mark(state).frame(width: EmberTokens.Spacing.space12, height: EmberTokens.Spacing.space12)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            // A17.1 — ink, never #B84D00 (law ③), never tappable (law ①). This is the sentence the whole screen was
            // missing: it names which day was done, which was missed, and when the next workout is.
            Text(lines.short)
                .font(.caption)
                .foregroundStyle(EmberColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true) // 6.7: it wraps, it never widens the column
        }
        // E20 — one sentence, not seven stops, and now the SAME sentence the eye gets, extended to full day names
        // (a screen reader says "Wed" letter by letter).
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(lines.spoken)
    }

    // done = a filled ember dot · today = an ink ring (you are here, nothing has happened yet) · missed = a large hollow
    // gray ring · nextUp = a small filled ink dot, the NEXT training day · upcoming = a small HOLLOW gray ring, every
    // planned day after that · rest = the smallest gray tick, a day the plan asks nothing of.
    //
    // A18.7 — `.upcoming` stops sharing a case with `.rest`. A17.4 marked the next training day only, so on a plan
    // training four days a week the ring said "of 4" while the strip could account for at most three of them: a
    // planned Friday was drawn exactly like a rest Saturday. A18.1 now prints the word "workouts" beside the ring,
    // which makes that a contradiction a reader can SEE, so the strip has to be countable against the ring.
    // `.upcoming` and `.missed` share a colour and differ in size and in position (past against future); the summary
    // sentence names the misses in words, so nothing rests on the size difference alone (6.5 / 1.4.1).
    @ViewBuilder
    private func mark(_ state: DayRingState) -> some View {
        switch state {
        case .done:
            Circle().fill(EmberColors.ember).frame(width: EmberTokens.Spacing.space12, height: EmberTokens.Spacing.space12)
        case .today:
            Circle().stroke(EmberColors.inkText, lineWidth: EmberTokens.Size.hairline + EmberTokens.Size.hairline).frame(width: EmberTokens.Spacing.space12, height: EmberTokens.Spacing.space12)
        // H014 — these were `missedGray` (2.39:1) and `hairline` (1.19:1) on the bone canvas, both under 6.5's 3:1
        // non-text gate. `secondaryText` measures 5.18:1 and is still a warm gray, so A8 holds and no law moves.
        // Thickening a stroke would not have changed the ratio.
        case .missed:
            Circle().stroke(EmberColors.secondaryText, lineWidth: EmberTokens.Size.hairline).frame(width: EmberTokens.Spacing.space12, height: EmberTokens.Spacing.space12)
        case .nextUp:
            Circle().fill(EmberColors.inkText).frame(width: EmberTokens.Spacing.space8, height: EmberTokens.Spacing.space8)
        case .upcoming:
            Circle().stroke(EmberColors.secondaryText, lineWidth: EmberTokens.Size.hairline).frame(width: EmberTokens.Spacing.space8, height: EmberTokens.Spacing.space8)
        case .rest:
            Circle().fill(EmberColors.secondaryText).frame(width: EmberTokens.Spacing.space4, height: EmberTokens.Spacing.space4)
        }
    }
}
