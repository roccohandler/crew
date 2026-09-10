// SPEC: Flow 3 (PR celebrations) · Flow 9 layer 3 (only where weights were logged) · README kind achievements `prCount` ·
// 5.6.1 Award.prBadge(exercise). A "new best" is a completed session whose best done work-set weight for an exercise beats
// every EARLIER completed session's best, where an earlier logged weight exists. Pure. Twin of
// web/src/lib/engine/personal-records.ts. A9 — every set carries the unit it was ENTERED in, and bests are compared on ONE
// normalised scale, so a preference change can never fire a false record or hide a real one. WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct RecordSet: Equatable {
    let done: Bool
    let isWarmup: Bool
    let weight: Double?
    var weightUnit: String? = nil // A9: absent on a row logged before the split — falls back to the account's own unit
}

struct RecordExercise: Equatable {
    let exerciseId: String
    let name: String
    let sets: [RecordSet]
}

struct RecordSession: Equatable {
    let completedAt: Date
    let exercises: [RecordExercise]
}

enum PersonalRecords {
    // SPEC: A9 — the returned value is a COMPARISON scale (kilograms), never a number to display: two weights entered in
    // different units are only orderable once normalised
    static func bestWeight(_ sets: [RecordSet], accountUnit: String = "lb") -> Double {
        sets.filter { $0.done && !$0.isWarmup }.compactMap { set in set.weight.map { WeightUnits.normalizedForCompare($0, unit: set.weightUnit ?? accountUnit) } }.max() ?? 0
    }

    // The exercises of `current` that set a new best against `earlier` (any order) — the celebration's PR badges
    static func newRecords(_ current: [RecordExercise], earlier: [RecordSession], accountUnit: String = "lb") -> [String] {
        var records: [String] = []
        for exercise in current {
            let best = bestWeight(exercise.sets, accountUnit: accountUnit)
            guard best > 0 else { continue }
            let previousBest = earlier.flatMap { session in session.exercises.filter { $0.exerciseId == exercise.exerciseId }.map { bestWeight($0.sets, accountUnit: accountUnit) } }.max() ?? 0
            if previousBest > 0, best > previousBest { records.append(exercise.name) }
        }
        return records
    }

    // Every (session, exercise) new best across a history, folded chronologically
    static func prCount(_ sessions: [RecordSession], accountUnit: String = "lb") -> Int {
        let chronological = sessions.sorted { $0.completedAt < $1.completedAt }
        var count = 0
        for (index, session) in chronological.enumerated() {
            count += newRecords(session.exercises, earlier: Array(chronological[0..<index]), accountUnit: accountUnit).count
        }
        return count
    }
}
