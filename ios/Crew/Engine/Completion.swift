// SPEC: V32 (≥1 work set done = complete) · V33 (done and asPlanned separately) · Flow 3 (warm-ups excluded from every
// count; "—" is a complete set). Twin of completion.ts. WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct SetFacts: Codable, Equatable {
    let targetReps: Int
    let actualReps: Int
    let done: Bool
    let isWarmup: Bool
}

struct SetOutcome: Codable, Equatable {
    let done: Bool
    let asPlanned: Bool
}

struct CompletionFacts: Codable, Equatable {
    let complete: Bool
    let setsDone: Int
    let setsPlanned: Int
    let setsAsPlanned: Int
    let sets: [SetOutcome]
}

enum Completion {
    static func asPlanned(_ set: SetFacts) -> Bool {
        set.done && set.actualReps >= set.targetReps
    }

    static func completionFacts(_ sets: [SetFacts]) -> CompletionFacts {
        let work = sets.filter { !$0.isWarmup }
        let setsDone = work.filter(\.done).count
        return CompletionFacts(
            complete: setsDone >= 1,
            setsDone: setsDone,
            setsPlanned: work.count,
            setsAsPlanned: work.filter(asPlanned).count,
            sets: sets.map { SetOutcome(done: $0.done, asPlanned: asPlanned($0)) }
        )
    }
}
