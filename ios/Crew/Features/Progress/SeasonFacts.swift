// SPEC: A28 (e) (owner-approved 2026-09-19) — "This season · N weeks · N workouts" at the top of Progress: a LABEL computed from the
// plan's history, NO engine rule, no vector, no stored field. A season runs from the last build or rebuild, or the end of the last
// pause, whichever is later, to today. GAP 10 read conservatively (R-086): the phone stores neither a rebuild's date nor a pause
// ended early, so a season starts at the plan's FIRST training-days entry (its build, A27 (a)) or at the end of the latest pause the
// phone still holds that has run its course — the later of the two; a days change is never a restart (R-083 (14)). Weeks are the
// calendar weeks it touches, this one included; workouts are completed workouts (a standalone cardio log is not one, A14).
// Twin of web/src/lib/progress-facts.ts seasonFacts — identical cases in both suites.

import Foundation

struct SeasonFacts: Equatable {
    let startDayKey: String
    let weeks: Int
    let workouts: Int

    // "This season · 6 weeks · 18 workouts"
    var line: String {
        "This season · \(weeks) \(weeks == 1 ? "week" : "weeks") · \(workouts) \(workouts == 1 ? "workout" : "workouts")"
    }

    // SPEC: A28 (e) · GAP 10 (R-086) — nil with no plan history: no season has started, so no line is drawn
    static func of(history: [TrainingDaysEntry], endedPauseDays: [String], workoutDayKeys: [String], todayKey: String) -> SeasonFacts? {
        guard let built = history.first?.from, built <= todayKey else { return nil }
        let start = max(built, endedPauseDays.filter { $0 <= todayKey }.max() ?? built)
        let weeks = DayKey.daysBetween(DayKey.weekKey(for: start), DayKey.weekKey(for: todayKey)) / TimeUnits.daysPerWeek + 1
        return SeasonFacts(startDayKey: start, weeks: weeks, workouts: workoutDayKeys.filter { $0 >= start && $0 <= todayKey }.count)
    }
}
