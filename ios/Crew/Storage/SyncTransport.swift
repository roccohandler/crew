// SPEC: E19 — a photo post is delivered in two steps: upload the photo (POST photos → photoKey), then send the createPost op with
// the key; a failed upload keeps the op pending under the normal backoff (airplane mode is .offline — Api.perform — and counts
// no attempt, E6). Once the key exists the queued op keeps it (SyncQueue.attachPhotoKey), so a failed sync after a successful
// upload never uploads the photo twice. The one plain function SyncQueue.shared sends through. WRITTEN — UNVERIFIED (needs Mac). T027

import Foundation

enum SyncTransport {
    static func send(_ op: SyncOpDTO) async throws -> SyncResponseDTO {
        var op = op
        if op.kind == OpKind.createPost.rawValue, case .object(var object) = op.payload, case .string(let localPath)? = object["localPhotoPath"], object["photoKey"] == nil || object["photoKey"] == .null {
            let uploaded = try await Api.shared.uploadPhoto(fileURL: URL(fileURLWithPath: localPath), purpose: "post")
            try await SyncQueue.shared.attachPhotoKey(opId: op.opId, photoKey: uploaded.photoKey) // the key outlives this attempt
            object["photoKey"] = .string(uploaded.photoKey)
            object["localPhotoPath"] = nil
            op = SyncOpDTO(opId: op.opId, kind: op.kind, payload: .object(object))
        }
        return try await Api.shared.sync(ops: [op])
    }
}
