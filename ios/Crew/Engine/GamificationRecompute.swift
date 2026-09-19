// SPEC: 5.6.1 recompute — the same fold as the server (V77, V78; 12.4): facts by day, every day before asOfDayKey judged by a
// rollover once the first post exists. A22 G1 (a) (owner-approved 2026-09-18): the fold knows the plan — a day is REQUIRED only
// when it is a planned training weekday. A27 (a) (owner-approved 2026-09-18, overturning R-068 reading 1): the plan handed in is
// its training-days HISTORY, so every day is judged by the days in effect on it and every synthesized post carries the history
// (V85–V90); a completed post keeps its stamped isPlannedDay. Twin of gamification-recompute.ts. The phone's live path is
// GamificationLocal (apply + judgeElapsedDays); this fold runs against the vectors. WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct SessionFacts: Codable {
    let id: String
    let dayKey: String
    let completed: Bool
}

struct PostFacts: Codable {
    let dayKey: String
    let kind: PostKind
    let isPlannedDay: Bool
    let sessionId: String?
}

struct ReactionFacts: Codable {
    let dayKey: String
}

enum GamificationRecompute {
    static func recompute(sessions: [SessionFacts], posts: [PostFacts], reactions: [ReactionFacts], pauses: [Pause], asOfDayKey: String, trainingDays: [TrainingDaysEntry]) -> PublicState {
        recomputeState(sessions: sessions, posts: posts, reactions: reactions, pauses: pauses, asOfDayKey: asOfDayKey, trainingDays: trainingDays).publicState
    }

    static func recomputeState(sessions: [SessionFacts], posts: [PostFacts], reactions: [ReactionFacts], pauses: [Pause], asOfDayKey: String, trainingDays: [TrainingDaysEntry]) -> GamificationState {
        var state = GamificationState()
        let days = (posts.map(\.dayKey) + reactions.map(\.dayKey)).sorted()
        guard var day = days.first else { return state }
        var started = false
        while day <= asOfDayKey {
            for post in posts where post.dayKey == day {
                let completed = sessions.first { $0.id == post.sessionId }?.completed ?? false
                state = GamificationEngine.apply(.postCreated(kind: post.kind, dayKey: day, isPlannedDay: post.isPlannedDay, workoutCompleted: completed, trainingDays: trainingDays), to: state, pauses: pauses).0
                started = true
            }
            for _ in reactions.filter({ $0.dayKey == day }) {
                state = GamificationEngine.apply(.reactionGiven(dayKey: day), to: state, pauses: pauses).0
            }
            if day < asOfDayKey {
                // SPEC: A22 G1 (a) · A27 (a) — only a day planned by the days in effect ON it can be missed; a rest day is never required
                let hadRequirement = started && !GamificationEngine.isPaused(day, pauses: pauses) && TrainingDays.isPlannedOn(trainingDays, day)
                state = GamificationEngine.apply(.dayRolledOver(dayKey: day, hadRequirement: hadRequirement), to: state, pauses: pauses).0
            }
            day = DayKey.addDays(day, 1)
        }
        return state
    }
}
