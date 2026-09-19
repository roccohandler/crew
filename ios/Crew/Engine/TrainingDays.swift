// SPEC: A27 (a) as ruled 2026-09-18 (owner-approved) — a day is judged by the training days that were in effect ON that day. A
// change takes effect from the dayKey on which it is saved, forward, never backward; the history is append-only (never edited,
// never deleted), and a completed session is a fact that is never re-judged (its isPlannedDay stays as stamped). Twin of
// web/src/lib/engine/training-days.ts — identical names. Pure, Foundation only.

import Foundation

struct TrainingDaysEntry: Codable, Equatable {
    let from: String          // the dayKey these weekdays took effect
    let weekdays: [Int]       // ISO 1 = Monday … 7 = Sunday, sorted, unique
}

enum TrainingDays {
    // SPEC: A27 (a) — the entry in effect on dayKey is the last one whose `from` ≤ dayKey. A day before every entry takes the
    // first: before its first recorded change a plan has only ever had its first days (R-082). No history → no planned day.
    static func weekdaysOn(_ history: [TrainingDaysEntry], _ dayKey: String) -> [Int] {
        var weekdays = history.first?.weekdays ?? []
        for entry in history where entry.from <= dayKey { weekdays = entry.weekdays }
        return weekdays
    }

    // SPEC: A27 (a) — "was this day planned?", asked of the entry in effect on it; every reader asks it this way
    static func isPlannedOn(_ history: [TrainingDaysEntry], _ dayKey: String) -> Bool {
        weekdaysOn(history, dayKey).contains(DayKey.isoWeekday(dayKey))
    }

    // SPEC: A27 (a) — a change is APPENDED, in effect from the day it is saved; never from before the last entry, so a late-arriving
    // edit cannot reach behind one already in effect (R-082). The same days again append nothing.
    static func appendTrainingDays(_ history: [TrainingDaysEntry], weekdays: [Int], savedDayKey: String) -> [TrainingDaysEntry] {
        let sorted = Array(Set(weekdays)).sorted()
        if let last = history.last, last.weekdays == sorted { return history }
        let from = history.last.map { $0.from > savedDayKey ? $0.from : savedDayKey } ?? savedDayKey
        return history + [TrainingDaysEntry(from: from, weekdays: sorted)]
    }
}
