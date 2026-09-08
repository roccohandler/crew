// SPEC: shared/seed/achievements.json rules (earned once, the first time its trigger counter reaches threshold, never
// removed — V35) · README kind `achievements` (V45–V50) · 5.6.1 Award.achievement(id) · E8 (unlocks fold into the
// celebration). Pure: counters in, seed-ordered awards out. Twin of web/src/lib/engine/achievements.ts.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct AchievementCounters: Codable, Equatable {
    var postsTotal = 0
    var workoutsCompleted = 0
    var currentStreak = 0
    var perfectWeeks = 0
    var prCount = 0
    var shieldsConsumed = 0
    var comebacks = 0
    var crewJoined = 0
    var reactionsGiven = 0
    var crewFullPulseDays = 0
    var crewFullPulseWeeks = 0

    init() {}

    // README: a vector's `counters` names only the counters it cares about (the web twin takes a Partial) — a missing key is 0
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        postsTotal = try container.decodeIfPresent(Int.self, forKey: .postsTotal) ?? 0
        workoutsCompleted = try container.decodeIfPresent(Int.self, forKey: .workoutsCompleted) ?? 0
        currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        perfectWeeks = try container.decodeIfPresent(Int.self, forKey: .perfectWeeks) ?? 0
        prCount = try container.decodeIfPresent(Int.self, forKey: .prCount) ?? 0
        shieldsConsumed = try container.decodeIfPresent(Int.self, forKey: .shieldsConsumed) ?? 0
        comebacks = try container.decodeIfPresent(Int.self, forKey: .comebacks) ?? 0
        crewJoined = try container.decodeIfPresent(Int.self, forKey: .crewJoined) ?? 0
        reactionsGiven = try container.decodeIfPresent(Int.self, forKey: .reactionsGiven) ?? 0
        crewFullPulseDays = try container.decodeIfPresent(Int.self, forKey: .crewFullPulseDays) ?? 0
        crewFullPulseWeeks = try container.decodeIfPresent(Int.self, forKey: .crewFullPulseWeeks) ?? 0
    }

    func value(for trigger: String) -> Int {
        switch trigger {
        case "postsTotal": return postsTotal
        case "workoutsCompleted": return workoutsCompleted
        case "currentStreak": return currentStreak
        case "perfectWeeks": return perfectWeeks
        case "prCount": return prCount
        case "shieldsConsumed": return shieldsConsumed
        case "comebacks": return comebacks
        case "crewJoined": return crewJoined
        case "reactionsGiven": return reactionsGiven
        case "crewFullPulseDays": return crewFullPulseDays
        case "crewFullPulseWeeks": return crewFullPulseWeeks
        default: return 0
        }
    }
}

enum Achievements {
    static func achievementsEarned(_ counters: AchievementCounters, alreadyEarned: [String], definitions: [SeedAchievement] = SeedCatalog.shared.achievements) -> [Award] {
        var awards: [Award] = []
        for achievement in definitions where !alreadyEarned.contains(achievement.id) {
            if counters.value(for: achievement.trigger) >= achievement.threshold { awards.append(.achievement(id: achievement.id)) }
        }
        return awards
    }
}
