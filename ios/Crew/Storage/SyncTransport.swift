// SPEC: 5.6.3 — the one plain function SyncQueue.shared sends through: one op per request, the server's per-op results back
// (airplane mode is .offline — Api.perform — and counts no attempt, E6). A22 G2 (owner-approved 2026-09-18): the two-step photo
// post (upload, then createPost with the key — E19) is gone with the plate journal; the profile picture uploads from
// EditProfileModel directly. WRITTEN — UNVERIFIED (needs Mac). T027

import Foundation

enum SyncTransport {
    static func send(_ op: SyncOpDTO) async throws -> SyncResponseDTO {
        try await Api.shared.sync(ops: [op])
    }
}
