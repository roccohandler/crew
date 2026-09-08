// SPEC: Flow 3 (PR celebrations) · Flow 9 layer 3 (only where weights were logged) · README kind achievements `prCount` ·
// 5.6.1 Award.prBadge(exercise). A "new best" is a completed session whose best done work-set weight for an exercise beats
// every EARLIER completed session's best, where an earlier logged weight exists. Pure. Twin of
// web/src/lib/engine/personal-records.ts. WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct RecordSet: Equatable {
    let done: Bool
    let isWarmup: Bool
    let weight: Double?
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
    static func bestWeight(_ sets: [RecordSet]) -> Double {
        sets.filter { $0.done && !$0.isWarmup }.compactMap(\.weight).max() ?? 0
    }

    // The exercises of `current` that set a new best against `earlier` (any order) — the celebration's PR badges
    static func newRecords(_ current: [RecordExercise], earlier: [RecordSession]) -> [String] {
        var records: [String] = []
        for exercise in current {
            let best = bestWeight(exercise.sets)
            guard best > 0 else { continue }
            let previousBest = earlier.flatMap { session in session.exercises.filter { $0.exerciseId == exercise.exerciseId }.map { bestWeight($0.sets) } }.max() ?? 0
            if previousBest > 0, best > previousBest { records.append(exercise.name) }
        }
        return records
    }

    // Every (session, exercise) new best across a history, folded chronologically
    static func prCount(_ sessions: [RecordSession]) -> Int {
        let chronological = sessions.sorted { $0.completedAt < $1.completedAt }
        var count = 0
        for (index, session) in chronological.enumerated() {
            count += newRecords(session.exercises, earlier: Array(chronological[0..<index])).count
        }
        return count
    }
}
