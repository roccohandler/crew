// SPEC: Part VIII V01–V44 · 5.6.1 GamificationEngine (state in, state out; one event type; awards) · shared/vectors/README.md.
// Twin of web/src/lib/engine/gamification.ts — identical names. Pure functions, Foundation only; the dayKey of every
// event is computed by the caller with the device timezone of that moment (V10). Handlers: GamificationPost.swift,
// GamificationDay.swift; recompute: GamificationRecompute.swift. WRITTEN — UNVERIFIED (needs Mac). T017–T019

import Foundation

struct Pause: Codable, Equatable {
    let startDay: String
    let endDay: String   // return day, exclusive
}

struct DayCounters: Codable, Equatable {
    var key: String?
    var posts = 0
    var meals = 0
    var workouts = 0     // completed workouts only
    var reactions = 0
}

struct WeekFacts: Codable, Equatable {
    var key: String?
    var posted: [String] = []
    var planned: [String] = []
    var plannedDone: [String] = []
    var awarded = false
}

// README kind achievements: tallies of awards emitted so far — engine memory, reverted with the day on undo
struct AchievementTallies: Codable, Equatable {
    var perfectWeeks = 0
    var shieldsConsumed = 0
    var comebacks = 0
}

// Part IX fields, then the engine's own memory (never asserted by vectors). An engineStateJSON written before
// tallies existed fails to decode and GamificationLocal starts a fresh memory from the public fields (no installs yet).
struct GamificationState: Codable, Equatable {
    var currentStreak = 0
    var longestStreak = 0
    var totalXP = 0
    var level = SpecConstants.startingLevel
    var shields = 0
    var lastCountedDayKey: String?
    var earnedAchievementIds: [String] = []
    var day = DayCounters()
    var week = WeekFacts()
    var judgedThroughDayKey: String?
    var tallies = AchievementTallies()
    var undo: [String: [Data]] = [:]   // per-day stack of encoded snapshots taken before each post

    var publicState: PublicState {
        PublicState(currentStreak: currentStreak, longestStreak: longestStreak, totalXP: totalXP, level: level, shields: shields, lastCountedDayKey: lastCountedDayKey, earnedAchievementIds: earnedAchievementIds)
    }
}

struct PublicState: Codable, Equatable {
    var currentStreak: Int
    var longestStreak: Int
    var totalXP: Int
    var level: Int
    var shields: Int
    var lastCountedDayKey: String?
    var earnedAchievementIds: [String]
}

enum PostKind: String, Codable {
    case workout, meal, text
}

enum GameEvent: Equatable {
    case postCreated(kind: PostKind, dayKey: String, isPlannedDay: Bool, workoutCompleted: Bool)
    case postUndone(dayKey: String)
    case dayRolledOver(dayKey: String, hadRequirement: Bool)
    case reactionGiven(dayKey: String)
}

enum XpReason: String, Codable {
    case firstPostOfDay, plannedWorkout, bonusWorkout, meal, reaction, comeback, perfectWeek
}

enum Award: Equatable {
    case xp(Int, reason: XpReason)
    case streakTo(Int)
    case comeback
    case perfectWeek
    case shieldEarned
    case shieldConsumed
    case levelUp(Int)
    case achievement(id: String)
    case prBadge(exercise: String)
}

enum GamificationEngine {
    // SPEC: G2 — level N requires totalXP ≥ levelBaseXp × (N−1) × N / 2
    static func levelFor(totalXP: Int) -> Int {
        var level = SpecConstants.startingLevel
        while totalXP >= SpecConstants.levelBaseXp * level * (level + 1) / SpecConstants.levelFormulaDivisor { level += 1 }
        return level
    }

    static func isPaused(_ dayKey: String, pauses: [Pause]) -> Bool {
        pauses.contains { $0.startDay <= dayKey && dayKey < $0.endDay }
    }

    // SPEC: 5.6.1 — apply(_ e: GameEvent, to: GamificationState, pauses: [Pause]) -> (GamificationState, [Award])
    static func apply(_ event: GameEvent, to state: GamificationState, pauses: [Pause]) -> (GamificationState, [Award]) {
        var next = state
        let awards: [Award]
        switch event {
        case .postCreated(let kind, let dayKey, let isPlannedDay, let workoutCompleted):
            awards = GamificationPost.applyPostCreated(&next, kind: kind, dayKey: dayKey, isPlannedDay: isPlannedDay, workoutCompleted: workoutCompleted, pauses: pauses)
        case .postUndone(let dayKey):
            awards = GamificationDay.applyPostUndone(&next, dayKey: dayKey)
        case .dayRolledOver(let dayKey, let hadRequirement):
            awards = GamificationDay.applyDayRolledOver(&next, dayKey: dayKey, hadRequirement: hadRequirement, pauses: pauses)
        case .reactionGiven(let dayKey):
            awards = GamificationDay.applyReactionGiven(&next, dayKey: dayKey, pauses: pauses)
        }
        return (next, awards)
    }
}
