// SPEC: docs/api.md users/me (GET · PATCH · DELETE), users/me/export, pause (GET · POST · DELETE), crews/[id]/mute, push-token,
// reports, blocks — DTOs mirror lib/validate.ts and lib/validate-crews.ts. WRITTEN — UNVERIFIED (needs Mac). T033/T034/T041

import Foundation

// PATCH semantics (docs/api.md): an absent key leaves the field alone, an explicit null clears the reminder or the photo.
// SPEC: A7 — notificationPrefs is a PARTIAL object (NotificationPrefsPatchDTO, ApiModels.swift): only the toggle that changed
// goes on the wire, the server merges it over the stored preferences (lib/validate.ts notificationPrefsSchema.partial())
struct UpdateMeRequestDTO: Codable {
    var displayName: String? = nil
    var units: String? = nil
    var timezone: String? = nil
    var reminderTime: String? = nil
    var clearsReminder = false
    var profilePhotoKey: String? = nil       // E1: a key from photos with purpose profile, the caller's own (A7)
    var clearsProfilePhoto = false
    var notificationPrefs: NotificationPrefsPatchDTO? = nil
    var welcomeBackAckDay: String? = nil

    enum CodingKeys: String, CodingKey {
        case displayName, units, timezone, reminderTime, profilePhotoKey, notificationPrefs, welcomeBackAckDay
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(displayName, forKey: .displayName)
        try container.encodeIfPresent(units, forKey: .units)
        try container.encodeIfPresent(timezone, forKey: .timezone)
        if clearsReminder { try container.encodeNil(forKey: .reminderTime) } else { try container.encodeIfPresent(reminderTime, forKey: .reminderTime) }
        if clearsProfilePhoto { try container.encodeNil(forKey: .profilePhotoKey) } else { try container.encodeIfPresent(profilePhotoKey, forKey: .profilePhotoKey) }
        try container.encodeIfPresent(notificationPrefs, forKey: .notificationPrefs)
        try container.encodeIfPresent(welcomeBackAckDay, forKey: .welcomeBackAckDay)
    }
}

struct PauseDTO: Codable, Equatable {
    let startDay: String
    let endDay: String
}

struct PauseReplyDTO: Codable {
    let pause: PauseDTO?
    let gamification: GamificationStateDTO?
}

struct CreatePauseRequestDTO: Codable {
    let startDay: String
    let endDay: String
    let timezone: String
}

struct MuteRequestDTO: Codable {
    let muted: Bool
}

struct MuteReplyDTO: Codable {
    let muted: Bool
}

struct DeleteAccountRequestDTO: Codable {
    let confirm: String
}

struct PushTokenRequestDTO: Codable {
    let token: String
    let platform: String
}

struct ReportRequestDTO: Codable {
    let targetType: String
    let targetId: String
    let reason: String
}

struct ReportReplyDTO: Codable {
    let reportId: String
}

struct BlockRequestDTO: Codable {
    let userId: String
}

// GET users/me — the account's server-side facts in one trip (user · gamification · pause · crew summary), read by a fresh
// phone's hydration (ServerHydrate)
struct MeCrewDTO: Codable, Equatable {
    let id: String
    let name: String
    let emoji: String
    let muted: Bool
}

struct MeDTO: Codable {
    let user: UserDTO
    let gamification: GamificationStateDTO
    let pause: PauseDTO?
    let crew: MeCrewDTO?
}

extension Api {
    func me() async throws -> MeDTO { try await send("GET", "users/me") }
    func updateMe(_ body: UpdateMeRequestDTO) async throws -> UserDTO { try await send("PATCH", "users/me", body: body) }
    func deleteAccount() async throws -> OkDTO { try await send("DELETE", "users/me", body: DeleteAccountRequestDTO(confirm: "delete")) }
    func currentPause() async throws -> PauseReplyDTO { try await send("GET", "pause") }
    func createPause(startDay: String, endDay: String, timezone: String) async throws -> PauseReplyDTO { try await send("POST", "pause", body: CreatePauseRequestDTO(startDay: startDay, endDay: endDay, timezone: timezone)) }
    func endPause() async throws -> OkDTO { try await send("DELETE", "pause") }
    func muteCrew(crewId: String, muted: Bool) async throws -> MuteReplyDTO { try await send("PATCH", "crews/\(crewId)/mute", body: MuteRequestDTO(muted: muted)) }
    func registerPushToken(_ token: String) async throws -> OkDTO { try await send("POST", "push-token", body: PushTokenRequestDTO(token: token, platform: "ios")) }
    func report(targetType: String, targetId: String, reason: String) async throws -> ReportReplyDTO { try await send("POST", "reports", body: ReportRequestDTO(targetType: targetType, targetId: targetId, reason: reason)) }
    func block(userId: String) async throws -> OkDTO { try await send("POST", "blocks", body: BlockRequestDTO(userId: userId)) }

    // The export is raw JSON bytes, not a typed reply
    func exportJSON() async throws -> Data {
        var request = URLRequest(url: baseURL.appending(path: "users/me/export"))
        request.setValue("Bearer \(try await AuthStore.shared.validAccessToken())", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, HttpStatus.successRange.contains(http.statusCode) else { throw AppError.invalidResponse }
        return data
    }
}
