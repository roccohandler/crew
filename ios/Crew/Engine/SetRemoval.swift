// SPEC: A11 (owner-directed 2026-09-09) — a set can be removed. Owner-reported: "there should be an area to remove a set
// for a user"; before this, one accidental tap on "+ set" permanently changed the workout's denominator, which feeds the
// live x/y line, the celebration, the shared post summary and the journal forever.
//
// Two rules make removal safe rather than merely possible:
//   ① the remaining rows are renumbered from zero, so `order` stays dense and a later patch cannot address a hole;
//   ② an exercise never drops below one set — Flow 3's whole model is that a set row IS the exercise, and an exercise with
//      no rows could neither be logged nor skipped. The floor counts WORK sets: deleting the last work set is refused even
//      when warm-ups remain, because warm-ups are excluded from every count (x/y, completion, PRs).
// Pure — it takes and returns plain facts, so the vectors can run it without SwiftData.
// Twin of web/src/lib/engine/set-removal.ts.

import Foundation

struct RemovableSet: Equatable {
    var order: Int
    let isWarmup: Bool
}

struct RemovalResult: Equatable {
    let removed: Bool
    let sets: [RemovableSet]
}

enum SetRemoval {
    // SPEC: A11 — remove the row at `order`, renumber the rest from zero, and refuse the removal that would leave no work set
    static func removeSet(_ sets: [RemovableSet], order: Int) -> RemovalResult {
        let ordered = sets.sorted { $0.order < $1.order }
        guard let target = ordered.first(where: { $0.order == order }) else { return RemovalResult(removed: false, sets: ordered) }
        let workSets = ordered.filter { !$0.isWarmup }.count
        if !target.isWarmup && workSets <= 1 { return RemovalResult(removed: false, sets: ordered) } // ② the floor
        let kept = ordered.filter { $0.order != order }
        return RemovalResult(removed: true, sets: kept.enumerated().map { RemovableSet(order: $0.offset, isWarmup: $0.element.isWarmup) }) // ① dense again
    }

    // SPEC: A11 — what the x/y denominator becomes after a removal: work sets only, warm-ups never (Flow 3)
    static func setsPlanned(_ sets: [RemovableSet]) -> Int {
        sets.filter { !$0.isWarmup }.count
    }
}
