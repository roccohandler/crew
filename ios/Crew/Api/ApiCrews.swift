// SPEC: docs/api.md crews/* + reactions + the blocked list (GET blocks · DELETE blocks, A7) — DTOs mirror lib/validate-crews.ts,
// crew-stream.ts and lib/blocks.ts 1:1; a stream post is a PostDTO (its A6 summary rides along). A21.2 / W3 (owner-approved
// 2026-09-17): the chat is gone — no message payload, no message routes; a stream item is a post or a system line; renameCrew is
// the Captain's PATCH crews/[id] (E2), reached from the Invite screen. WRITTEN — UNVERIFIED (needs Mac). T031

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

// One stream item (Flow 6) — kind post | system. `body`/`deleted` stay optional so a snapshot written before A21.2 still decodes;
// StreamList renders nothing for a kind it no longer knows.
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

// SPEC: E2 · docs/api.md PATCH crews/[id] — { name?, emoji? } → { crew: { id, name, emoji } }
struct RenameCrewRequestDTO: Codable {
    let name: String?
    let emoji: String?
}

struct RenamedCrewDTO: Codable {
    let id: String
    let name: String
    let emoji: String
}

struct RenameCrewReplyDTO: Codable {
    let crew: RenamedCrewDTO
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

// SPEC: A7 — Settings › Blocked people: { blocked: [{ userId, displayName }] }, oldest block first
struct BlockedUserDTO: Codable, Equatable, Identifiable {
    let userId: String
    let displayName: String

    var id: String { userId }
}

struct BlockedListDTO: Codable {
    let blocked: [BlockedUserDTO]
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
    func renameCrew(crewId: String, name: String?, emoji: String?) async throws -> RenameCrewReplyDTO { try await send("PATCH", "crews/\(crewId)", body: RenameCrewRequestDTO(name: name, emoji: emoji)) }

    // SPEC: A7 — the people this user blocked, and the unblock (DELETE blocks { userId }; a 404 means it was already undone)
    func blockedUsers() async throws -> [BlockedUserDTO] {
        let reply: BlockedListDTO = try await send("GET", "blocks")
        return reply.blocked
    }

    func unblock(userId: String) async throws -> OkDTO { try await send("DELETE", "blocks", body: BlockRequestDTO(userId: userId)) }
}
