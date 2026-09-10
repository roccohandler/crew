// SPEC: A14 (owner-directed 2026-09-09) — the seven-day strip. HomeModel has always computed `weeklyRing: [DayRingState]`
// (done · missed · rest · today · upcoming) and passed it straight into WeeklyRing(days:), WHICH NEVER READ THE PARAMETER
// (F12). So the user saw "2/4" and one continuous arc and could not tell WHICH two days they hit. This renders the states
// that were already there — no new computation, no new query, no new state.
//
// Part III law ④ — a done day is the one place ember belongs here (progress IS the message); everything else is ink or the
// missed gray, and the strip is never a control: it reports, it does not navigate (there is nothing to navigate TO —
// tapping a past day is Progress's job, and Home must not grow a second destination for it).
// 6.5: the marks carry a shape as well as a colour, so the strip reads in grayscale and under every CVD model.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct WeekStrip: View {
    let days: [DayRingState]
    private let initials = ["M", "T", "W", "T", "F", "S", "S"] // ISO order, Monday weeks (Appendix A policy)

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(days.prefix(TimeUnits.daysPerWeek).enumerated()), id: \.offset) { index, state in
                VStack(spacing: EmberTokens.Spacing.rowGap) {
                    Text(initials[index]).font(.caption2).foregroundStyle(EmberColors.secondaryText)
                    mark(state)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summary)
    }

    // done = a filled ember dot · today = an ink ring (you are here, nothing has happened yet) · missed = a hollow gray dot
    // · rest = a small neutral tick · upcoming = the same tick, quieter. Four shapes, so colour is never the only channel.
    @ViewBuilder
    private func mark(_ state: DayRingState) -> some View {
        switch state {
        case .done:
            Circle().fill(EmberColors.ember).frame(width: EmberTokens.Spacing.space12, height: EmberTokens.Spacing.space12)
        case .today:
            Circle().stroke(EmberColors.inkText, lineWidth: EmberTokens.Size.hairline + EmberTokens.Size.hairline).frame(width: EmberTokens.Spacing.space12, height: EmberTokens.Spacing.space12)
        case .missed:
            Circle().stroke(EmberColors.missedGray, lineWidth: EmberTokens.Size.hairline).frame(width: EmberTokens.Spacing.space12, height: EmberTokens.Spacing.space12)
        case .rest, .upcoming:
            Circle().fill(EmberColors.hairline).frame(width: EmberTokens.Spacing.space4, height: EmberTokens.Spacing.space4)
        }
    }

    // E20 — one sentence, not seven stops. A8: the count is stated only when there is one; "no workouts yet this week" is
    // never phrased as a zero.
    private var summary: String {
        let done = days.filter { $0 == .done }.count
        let missed = days.filter { $0 == .missed }.count
        if done == 0 && missed == 0 { return "This week: nothing logged yet" }
        let workouts = done == 1 ? "1 workout" : "\(done) workouts"
        return missed == 0 ? "This week: \(workouts) done" : "This week: \(workouts) done, \(missed) missed"
    }
}
