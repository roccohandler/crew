// SPEC: docs/api.md crews/* + messages + reactions — DTOs mirror lib/validate-crews.ts and crew-stream.ts 1:1.
// WRITTEN — UNVERIFIED (needs Mac). T031

import Foundation

struct CrewDTO: Codable, Equatable {
    let id: String
    let name: String
    let emoji: String
    let captainId: String
    let inviteLink: String?
    let muted: Bool?
}

struct PulseDTO: Codable, Equatable {
    let posted: Int
    let total: Int
}

struct MyCrewDTO: Codable {
    let crew: CrewDTO?
    let members: [MemberDot]?
    let pulse: PulseDTO?
}

struct ReactionSummaryDTO: Codable, Equatable {
    let emoji: String
    let userId: String
}

// One stream item (Flow 6: posts drop into the chat) — kind post | message | system
struct StreamItemDTO: Codable, Equatable, Identifiable {
    let kind: String
    let at: Date
    let userId: String
    let post: PostDTO?
    let reactions: [ReactionSummaryDTO]?
    let comeback: Bool?
    let id: String?
    let body: String?
    let deleted: Bool?

    var itemId: String { id ?? post?.id ?? "\(kind)-\(at.timeIntervalSince1970)" }
}

struct StreamDTO: Codable {
    let items: [StreamItemDTO]
    let windowDays: Int
    let pulse: PulseDTO
    let members: [MemberDot]
    let serverTime: Date
}

struct CreateCrewRequestDTO: Codable {
    let name: String
    let emoji: String
}

struct CreateCrewReplyDTO: Codable {
    let crew: CrewDTO
}

struct SendMessagePayload: Codable {
    let crewId: String
    let clientId: String
    let body: String
}

struct ReactPayload: Codable {
    let postId: String
    let emoji: String
}

struct UnreactPayload: Codable {
    let postId: String
}

struct RemoveMemberRequestDTO: Codable {
    let userId: String?
}

struct InviteReplyDTO: Codable {
    let inviteLink: String
}

extension Api {
    func myCrew() async throws -> MyCrewDTO { try await send("GET", "crews") }
    func createCrew(name: String, emoji: String) async throws -> CreateCrewReplyDTO { try await send("POST", "crews", body: CreateCrewRequestDTO(name: name, emoji: emoji)) }
    func stream(crewId: String, since: Date?) async throws -> StreamDTO {
        let query = since.map { [URLQueryItem(name: "since", value: ISO8601DateFormatter().string(from: $0))] } ?? []
        return try await send("GET", "crews/\(crewId)/stream", query: query)
    }
    func leaveOrRemove(crewId: String, userId: String?) async throws -> OkDTO { try await send("DELETE", "crews/\(crewId)/members", body: RemoveMemberRequestDTO(userId: userId)) }
    func regenerateInvite(crewId: String) async throws -> InviteReplyDTO { try await send("POST", "crews/\(crewId)/invite") }
}
