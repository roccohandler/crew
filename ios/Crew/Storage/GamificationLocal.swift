// SPEC: 5.3 the optimistic-write pattern (mutate SwiftData → update model → enqueue → server reconciles) applied to
// gamification: the local engine state persists in LocalGamificationState.engineStateJSON, apply() runs on every post,
// elapsed days are judged on foreground (README: a rollover is the sole judge of a miss), and the server state REPLACES
// the public fields on reconcile (5.6.3). Plain functions (C2). WRITTEN — UNVERIFIED (needs Mac). T024

import Foundation
import SwiftData

@MainActor
enum GamificationLocal {
    static func engineState(for userId: String, store: Store) throws -> GamificationState {
        let local = try store.gamificationState(for: userId)
        if let data = local.engineStateJSON, let saved = try? JSONDecoder.crew.decode(GamificationState.self, from: data) {
            var state = saved
            state.currentStreak = local.currentStreak
            state.longestStreak = local.longestStreak
            state.totalXP = local.totalXP
            state.level = local.level
            state.shields = local.shields
            state.lastCountedDayKey = local.lastCountedDayKey
            state.earnedAchievementIds = local.earnedAchievementIds
            return state
        }
        var state = GamificationState()
        state.currentStreak = local.currentStreak
        state.longestStreak = local.longestStreak
        state.totalXP = local.totalXP
        state.level = local.level
        state.shields = local.shields
        state.lastCountedDayKey = local.lastCountedDayKey
        state.earnedAchievementIds = local.earnedAchievementIds
        return state
    }

    static func persist(_ state: GamificationState, for userId: String, store: Store) throws {
        let local = try store.gamificationState(for: userId)
        local.currentStreak = state.currentStreak
        local.longestStreak = state.longestStreak
        local.totalXP = state.totalXP
        local.level = state.level
        local.shields = state.shields
        local.lastCountedDayKey = state.lastCountedDayKey
        local.earnedAchievementIds = state.earnedAchievementIds
        local.engineStateJSON = try JSONEncoder.crew.encode(state)
        local.updatedAt = Date()
        try store.save()
    }

    static func pauses(for userId: String, store: Store) throws -> [Pause] {
        try store.context.fetch(FetchDescriptor<LocalPause>(predicate: #Predicate { $0.userId == userId })).map { Pause(startDay: $0.startDay, endDay: $0.endDay) }
    }

    // SPEC: 5.6.1 apply — one event in, awards out, state persisted; then the achievements pass on the solo counters (E8):
    // unlocked ids are appended after levelUp (canonical order) and never removed (V35). Crew achievements arrive with the
    // server's state on reconcile — GAP: they have no celebration moment on the phone (logged, ratification R-037).
    static func apply(_ event: GameEvent, for userId: String, store: Store) throws -> [Award] {
        var (next, awards) = GamificationEngine.apply(event, to: try engineState(for: userId, store: store), pauses: try pauses(for: userId, store: store))
        let unlocked = Achievements.achievementsEarned(try AchievementFacts.soloCounters(for: userId, state: next, store: store), alreadyEarned: next.earnedAchievementIds)
        for award in unlocked { if case .achievement(let id) = award { next.earnedAchievementIds.append(id) } }
        awards.append(contentsOf: unlocked)
        try persist(next, for: userId, store: store)
        return awards
    }

    // SPEC: E8 / V04 — every day since the last judged one (up to yesterday) is rolled over on foreground
    static func judgeElapsedDays(for userId: String, store: Store, now: Date = Date(), timeZone: TimeZone = .current) throws -> [Award] {
        var state = try engineState(for: userId, store: store)
        let pauses = try pauses(for: userId, store: store)
        let today = DayKey.dayKey(for: now, tz: timeZone)
        guard let firstDay = state.judgedThroughDayKey.map({ DayKey.addDays($0, 1) }) ?? state.lastCountedDayKey else { return [] }
        var awards: [Award] = []
        var day = firstDay
        while day < today {
            let hadRequirement = state.lastCountedDayKey != nil && !GamificationEngine.isPaused(day, pauses: pauses)
            let result = GamificationEngine.apply(.dayRolledOver(dayKey: day, hadRequirement: hadRequirement), to: state, pauses: pauses)
            state = result.0
            awards += result.1
            day = DayKey.addDays(day, 1)
        }
        try persist(state, for: userId, store: store)
        return awards
    }
}
