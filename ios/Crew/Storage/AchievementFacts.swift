// SPEC: README kind achievements — the SOLO counters derived from the phone's own store (posts, completed sessions, PRs) plus
// the engine's tallies, so an unlock can fold into the celebration offline (E8, E6). The crew counters (reactions given,
// crew full pulse) are the server's: they arrive with the reconciled state (5.6.3), never computed here. Twin of
// web/src/lib/achievement-facts.ts. WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import SwiftData

@MainActor
enum AchievementFacts {
    static func soloCounters(for userId: String, state: GamificationState, store: Store) throws -> AchievementCounters {
        let completed = try store.context.fetch(FetchDescriptor<LocalSession>(predicate: #Predicate { $0.userId == userId && $0.status == "completed" }))
        var counters = AchievementCounters()
        counters.postsTotal = try store.allPosts(for: userId).count
        counters.workoutsCompleted = completed.count
        counters.currentStreak = state.currentStreak
        counters.perfectWeeks = state.tallies.perfectWeeks
        counters.shieldsConsumed = state.tallies.shieldsConsumed
        counters.comebacks = state.tallies.comebacks
        counters.prCount = PersonalRecords.prCount(completed.map(recordSession), accountUnit: AuthStore.shared.weightUnit)
        counters.crewJoined = try store.crewSnapshot() == nil ? 0 : 1
        return counters
    }

    static func recordSession(_ session: LocalSession) -> RecordSession {
        RecordSession(completedAt: session.completedAt ?? session.startedAt, exercises: session.exercises.map { exercise in
            // A9: each set carries the unit it was ENTERED in, so bests compare on one normalised scale
            RecordExercise(exerciseId: exercise.exerciseId, name: exercise.name, sets: exercise.sets.map { RecordSet(done: $0.done, isWarmup: $0.isWarmup, weight: $0.weight, weightUnit: $0.weightUnit) })
        })
    }

    // Flow 3 PR celebration: this session against every earlier completed one (the same rule the server counts)
    static func newRecords(in session: LocalSession, store: Store) throws -> [String] {
        let clientId = session.clientId
        let userId = session.userId
        let earlier = try store.context.fetch(FetchDescriptor<LocalSession>(predicate: #Predicate { $0.userId == userId && $0.status == "completed" && $0.clientId != clientId }))
        return PersonalRecords.newRecords(recordSession(session).exercises, earlier: earlier.map(recordSession), accountUnit: AuthStore.shared.weightUnit)
    }
}
