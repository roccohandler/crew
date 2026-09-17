// SPEC: A20.1 / A20.2 (owner-directed 2026-09-11) — the three rows of TODAY'S LOG, built from facts Home already had.
//
// Split from HomeModel.swift for the C9 cap, the way HomeModel+Facts.swift and HomeModel+Edges.swift already split it.
// Screens hold ZERO logic (5.6.6), so every string a row renders is decided here.
//
// A8 RUNS THROUGH EVERY BRANCH: no row ever prints a zero as a verdict. An untouched row says what it is FOR
// ("Not logged today"), never "0" and never "0/15" — the same rule that took "0/3" off the bridge (W043), off every
// Monday (A18.2) and off the paused header (A18.6b). The mockup that prompted this pass prints "15/15 sets" with no
// pre-session grammar, and the honest value there is "0/15", which is the defect one layer down.
//
// THE WORKOUT ROW HAS THREE GRAMMARS, and which one renders is the whole point of A20.5 (the resume banner is gone —
// the row reports the open session instead) and A20.1 (the card is gone — the row IS the day's work):
//
//   not started   "Push day · 5 exercises + mobility"   ← the plan fact, from the same NextUp.sizeLine the card used
//   in progress   "Push day · 8 of 15 sets"             ← Completion.completionFacts works on an OPEN session
//   done          "Push day · 15/15 sets · 44 min"      ← JournalFacts.summaryLine, the journal's own sentence (C5)
//
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

extension HomeModel {
    // The plan's name for today's workout, or nil when the plan asks for nothing today. Read by the row builder and
    // by nothing else: `TodayState.workout` carries the name for the card, and A20.1 removed the card.
    private func workoutRowDetail() -> String {
        // In progress outranks everything: a session is open, so the honest report is how far in it is.
        if let session = resumeSession {
            let facts = Completion.completionFacts(SessionActions.setFacts(session))
            return "\(session.workoutName) · \(facts.setsDone) of \(facts.setsPlanned) sets"
        }
        // Done today: the journal's own sentence, so Home cannot drift from Progress or the journal (C5, A18.9).
        if vectors.workoutDone, let line = todaySummaryLines.first { return line }
        switch today {
        case .workout(let name, let exerciseCount, let hasCardio, _, _):
            return "\(name) · \(NextUp.sizeLine(exerciseCount: exerciseCount, hasCardio: hasCardio))"
        case .paused:
            return "Nothing planned — plan paused" // Flow 7: a frozen plan asks for nothing, and a bonus still earns zero (V20)
        default:
            return "Nothing planned — bonus anytime" // rest · all-done: A3 keeps the bonus reachable, and says so
        }
    }

    // SPEC: A2 — minutes, from cardio done ANYWHERE today (A20.10). A8: never "0 min".
    private func cardioRowDetail() -> String {
        guard let minutes = vectors.cardioMinutes else { return "Not logged today" }
        return "\(minutes) min"
    }

    // SPEC: A20.11 — the meal count and NOTHING ELSE. The mockup prints "2 meals · 1,240 kcal"; no calorie field exists
    // on either engine, A16 clause ⑥ says the plate journal carries "never a gram or a calorie", and A16.c gates the
    // whole nutrition-target surface to 18+ behind the owner's own ⏳ W070 task, which is still open. Building it early
    // is scope expansion by the 2026-09-10 ratification's own words. The count is already computed and is legal today.
    private func mealRowDetail() -> String {
        guard vectors.meals > 0 else { return "Nothing logged today" }
        return vectors.meals == 1 ? "1 meal" : "\(vectors.meals) meals"
    }

    // The three rows, ALWAYS in this order and always all three (A17.3 / F10: a slot that moves between states is why
    // nothing on this screen had a stable position). `offersQuickComplete` is A20.3's one named exception.
    var logRows: [HomeLogRow] {
        [
            HomeLogRow(id: "workout", verb: "Log workout", detail: workoutRowDetail(), glyph: "figure.strengthtraining.traditional", done: vectors.workoutDone, offersQuickComplete: quickCompleteAvailable),
            HomeLogRow(id: "cardio", verb: "Log cardio", detail: cardioRowDetail(), glyph: "figure.run", done: vectors.cardioMinutes != nil, offersQuickComplete: false),
            HomeLogRow(id: "meal", verb: "Log a meal", detail: mealRowDetail(), glyph: "fork.knife", done: vectors.meals > 0, offersQuickComplete: false),
        ]
    }

    // SPEC: A20.7 — the date line. Home is the one screen that states which day it is reasoning about, which is also
    // the cheapest check a user has against "is this thing up to date". It reads `todayKey` — the day `refresh()`
    // actually judged — and NOT the wall clock: every other fact on this screen comes from that key, so a date line
    // taken from `Date()` could state a different day than the state beneath it at exactly the moment that matters
    // (the 3 AM boundary, a timezone change, a phone left open past midnight). That is the bug this screen exists to
    // stop reporting, so it must not be the one committing it.
    var dateLine: String { todayKey.isEmpty ? "" : DayLabel.todayHeader(todayKey) }

    // SPEC: A3 — the one-sentence form the BRIDGE card renders (§1D: one CTA plus this line, nothing else). Derived,
    // never stored beside `nextUp`, so the row and the line can never say different things. It lives here rather than
    // in HomeModel.swift for the C9 cap, beside the other two strings Home computes for a view to render.
    var nextUpLine: String? { nextUp.map { "\($0.heading): \($0.detail)" } }
}
