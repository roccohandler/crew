// SPEC: docs/api.md POST sync — replay the offline queue in order; per-op results; the server gamification state
// REPLACES the client's (5.6.3). WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct SyncOpDTO: Codable {
    let opId: String
    let kind: String
    let payload: JSONValue     // the op's JSON body as the object it was queued with (syncOpSchema: a record, not a string)
}

struct SyncOpResultDTO: Codable {
    let opId: String
    let ok: Bool
    let error: String?
    let retryable: Bool?
}

struct SyncResponseDTO: Codable {
    let results: [SyncOpResultDTO]
    let gamification: GamificationStateDTO?
}

struct SyncRequestDTO: Codable {
    let timezone: String
    let ops: [SyncOpDTO]
}

extension Api {
    func sync(ops: [SyncOpDTO]) async throws -> SyncResponseDTO {
        try await send("POST", "sync", body: SyncRequestDTO(timezone: TimeZone.current.identifier, ops: ops))
    }
}
