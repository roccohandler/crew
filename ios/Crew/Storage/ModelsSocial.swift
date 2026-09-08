// SPEC: Part IX — Post, GamificationState, Pause and the crew snapshot as local @Model classes (offline-first, E6).
// The server state REPLACES the local gamification state on reconcile (5.6.3). WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import SwiftData

@Model
final class LocalPost {
    @Attribute(.unique) var clientId: String
    var serverId: String?
    var userId: String
    var type: String                 // workout | meal | text
    var sessionClientId: String?
    var photoKey: String?
    var localPhotoPath: String?      // pending upload (E19: counted vs delivered are separate facts)
    var caption: String
    var mealTag: String?
    var shareToCrew: Bool
    var dayKey: String
    var isPlannedDay: Bool
    var workoutCompleted: Bool
    var earlierToday: Bool
    var createdAt: Date
    var deliveredAt: Date?
    var deletedAt: Date?

    init(clientId: String, userId: String, type: String, sessionClientId: String?, caption: String, mealTag: String?, shareToCrew: Bool, dayKey: String, isPlannedDay: Bool, workoutCompleted: Bool, earlierToday: Bool, createdAt: Date) {
        self.clientId = clientId
        self.userId = userId
        self.type = type
        self.sessionClientId = sessionClientId
        self.caption = caption
        self.mealTag = mealTag
        self.shareToCrew = shareToCrew
        self.dayKey = dayKey
        self.isPlannedDay = isPlannedDay
        self.workoutCompleted = workoutCompleted
        self.earlierToday = earlierToday
        self.createdAt = createdAt
    }
}

@Model
final class LocalGamificationState {
    @Attribute(.unique) var userId: String
    var currentStreak: Int
    var longestStreak: Int
    var totalXP: Int
    var level: Int
    var shields: Int
    var lastCountedDayKey: String?
    var earnedAchievementIds: [String]
    var engineStateJSON: Data?       // the engine's own memory (day counters, week facts, undo) for optimistic apply()
    var updatedAt: Date

    init(userId: String) {
        self.userId = userId
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalXP = 0
        self.level = SpecConstants.startingLevel
        self.shields = 0
        self.lastCountedDayKey = nil
        self.earnedAchievementIds = []
        self.updatedAt = Date()
    }
}

@Model
final class LocalPause {
    var userId: String
    var startDay: String
    var endDay: String               // return day, exclusive
    var createdAt: Date

    init(userId: String, startDay: String, endDay: String, createdAt: Date) {
        self.userId = userId
        self.startDay = startDay
        self.endDay = endDay
        self.createdAt = createdAt
    }
}

// The last-synced crew view for the offline Crew tab (6.1 Offline: social shows last-synced + one thin banner)
@Model
final class LocalCrewSnapshot {
    @Attribute(.unique) var crewId: String
    var name: String
    var emoji: String
    var captainId: String
    var inviteToken: String?
    var streamJSON: Data             // the unified stream as last received
    var membersJSON: Data
    var syncedAt: Date

    init(crewId: String, name: String, emoji: String, captainId: String, inviteToken: String?, streamJSON: Data, membersJSON: Data, syncedAt: Date) {
        self.crewId = crewId
        self.name = name
        self.emoji = emoji
        self.captainId = captainId
        self.inviteToken = inviteToken
        self.streamJSON = streamJSON
        self.membersJSON = membersJSON
        self.syncedAt = syncedAt
    }
}
