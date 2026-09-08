// SPEC: 5.6.1 recompute — the same fold as the server (V36; 12.4): facts by day, every day before asOfDayKey judged by a
// rollover once the first post exists. Twin of gamification-recompute.ts. WRITTEN — UNVERIFIED (needs Mac).

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
    static func recompute(sessions: [SessionFacts], posts: [PostFacts], reactions: [ReactionFacts], pauses: [Pause], asOfDayKey: String) -> PublicState {
        recomputeState(sessions: sessions, posts: posts, reactions: reactions, pauses: pauses, asOfDayKey: asOfDayKey).publicState
    }

    static func recomputeState(sessions: [SessionFacts], posts: [PostFacts], reactions: [ReactionFacts], pauses: [Pause], asOfDayKey: String) -> GamificationState {
        var state = GamificationState()
        let days = (posts.map(\.dayKey) + reactions.map(\.dayKey)).sorted()
        guard var day = days.first else { return state }
        var started = false
        while day <= asOfDayKey {
            for post in posts where post.dayKey == day {
                let completed = sessions.first { $0.id == post.sessionId }?.completed ?? false
                state = GamificationEngine.apply(.postCreated(kind: post.kind, dayKey: day, isPlannedDay: post.isPlannedDay, workoutCompleted: completed), to: state, pauses: pauses).0
                started = true
            }
            for _ in reactions.filter({ $0.dayKey == day }) {
                state = GamificationEngine.apply(.reactionGiven(dayKey: day), to: state, pauses: pauses).0
            }
            if day < asOfDayKey {
                let hadRequirement = started && !GamificationEngine.isPaused(day, pauses: pauses)
                state = GamificationEngine.apply(.dayRolledOver(dayKey: day, hadRequirement: hadRequirement), to: state, pauses: pauses).0
            }
            day = DayKey.addDays(day, 1)
        }
        return state
    }
}
