// SPEC: 5.2 Api/ApiModels.swift — Codable DTOs mirroring the server zod schemas (lib/validate.ts) and docs/api.md
// response shapes, 1:1 by name. Auth + user + gamification shapes here; feature DTOs arrive with their tasks.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct UserDTO: Codable, Equatable {
    let id: String
    let email: String
    let authProvider: String
    let displayName: String
    let profilePhotoKey: String?
    let units: String
    let timezone: String
    let reminderTime: String?
    let notificationPrefs: NotificationPrefsDTO?   // A7: absent on an older reply = every toggle on (read `prefs`)
    let welcomeBackAckDay: String?   // E4: the day the welcome-back screen was answered (nil = never)
    let createdAt: Date

    var prefs: NotificationPrefsDTO { notificationPrefs ?? NotificationPrefsDTO.allOn }
}

// SPEC: A7 (owner-directed 2026-09-08) — per-row notification toggles, server-backed; the server fills defaults (all true)
struct NotificationPrefsDTO: Codable, Equatable {
    let workoutReminder: Bool
    let streakRisk: Bool
    let crewActivity: Bool

    static let allOn = NotificationPrefsDTO(workoutReminder: true, streakRisk: true, crewActivity: true)
}

// SPEC: A7 — PATCH users/me sends only the row that changed; the server merges it over the stored toggles
struct NotificationPrefsPatchDTO: Codable, Equatable {
    var workoutReminder: Bool? = nil
    var streakRisk: Bool? = nil
    var crewActivity: Bool? = nil
}

// docs/api.md — the iOS signed-in response (X-Crew-Client: ios)
struct AuthSessionDTO: Codable {
    let user: UserDTO
    let accessToken: String
    let refreshToken: String
    let accessExpiresAt: Date
}

struct RegisterRequestDTO: Codable {
    let email: String
    let password: String
    let displayName: String
    let timezone: String
    let eulaAccepted: Bool
    let birthYear: Int
}

struct LoginRequestDTO: Codable {
    let email: String
    let password: String
}

struct RefreshRequestDTO: Codable {
    let refreshToken: String
}

struct AppleSignInRequestDTO: Codable {
    let identityToken: String
    let displayName: String?
    let timezone: String
    let eulaAccepted: Bool
    let birthYear: Int?
}

struct ResetRequestDTO: Codable {
    let email: String
}

// Part IX GamificationState — server-derived truth; REPLACES local state on every sync (5.6.3)
struct GamificationStateDTO: Codable, Equatable {
    let currentStreak: Int
    let longestStreak: Int
    let totalXP: Int
    let level: Int
    let shields: Int
    let lastCountedDayKey: String?
    let earnedAchievementIds: [String]
}

struct ApiErrorBodyDTO: Codable {
    struct Inner: Codable {
        let code: String
        let message: String
    }
    let error: Inner
}

struct OkDTO: Codable {
    let ok: Bool
}

extension JSONDecoder {
    static let crew: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        return decoder
    }()
}

extension JSONEncoder {
    static let crew: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

private extension JSONDecoder.DateDecodingStrategy {
    // The server writes ISO-8601 with milliseconds ("2026-09-04T18:00:00.000Z"); accept both forms.
    static let iso8601WithFractionalSeconds = custom { decoder in
        let text = try decoder.singleValueContainer().decode(String.self)
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: text) { return date }
        let plain = ISO8601DateFormatter()
        if let date = plain.date(from: text) { return date }
        throw DecodingError.dataCorruptedError(in: try decoder.singleValueContainer(), debugDescription: "not an ISO-8601 date: \(text)")
    }
}
