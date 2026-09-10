// SPEC: Flow 3 "Pre-fill from reality — rows load your last ACTUAL performance" · A12 (owner-directed 2026-09-09). Until
// now that promise was only DISPLAYED: lastTimeLine computed the previous session's real reps and weight, rendered them as
// a grey caption, and threw the numbers away — every strength set still opened at "—", so reaching 225 lb cost 45 taps or a
// 5.3 s hold. This is the same lookup, used. A9: the unit the weight was entered in carries forward with it, so a prefilled
// row is never silently reinterpreted. Pure — the caller supplies the history. Twin of web/src/lib/engine/set-prefill.ts.

import Foundation

// One exercise's last real performance: the heaviest done work set, and the reps that went with it
struct PrefillFacts: Equatable {
    let reps: Int
    let weight: Double?
    let weightUnit: String?
}

// A previous session's rows for one exercise, newest first — what the store hands in
struct PrefillSet: Equatable {
    let actualReps: Int
    let weight: Double?
    let weightUnit: String?
    let done: Bool
    let isWarmup: Bool
}

enum SetPrefill {
    // SPEC: A12 — the heaviest DONE WORK set of the most recent session that has one. Warm-ups never count (Flow 3 excludes
    // them from every number), and an undone row is not a performance. Sessions arrive newest first; the first one with a
    // usable row wins, so a session where the exercise was skipped falls through to the one before it.
    static func facts(from sessions: [[PrefillSet]]) -> PrefillFacts? {
        for sets in sessions {
            let done = sets.filter { $0.done && !$0.isWarmup }
            guard !done.isEmpty else { continue }
            // Heaviest first; a bodyweight exercise has no weight at all, so fall back to the last done row's reps
            guard let heaviest = done.max(by: { ($0.weight ?? 0) < ($1.weight ?? 0) }) else { continue }
            return PrefillFacts(reps: heaviest.actualReps, weight: heaviest.weight, weightUnit: heaviest.weightUnit)
        }
        return nil
    }

    // SPEC: A12 — what a new row opens at. With no history the plan's targets stand exactly as before (nothing regresses
    // for a first-ever session); with history, reality wins. A weight of nil stays nil — "—" is still a complete set forever
    // for an exercise that has never carried a number.
    static func openingReps(targetReps: Int, facts: PrefillFacts?) -> Int {
        facts?.reps ?? targetReps
    }

    static func openingWeight(targetWeight: Double?, facts: PrefillFacts?) -> Double? {
        facts?.weight ?? targetWeight
    }
}
