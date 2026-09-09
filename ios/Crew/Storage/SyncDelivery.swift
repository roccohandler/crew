// SPEC: E19 — counted vs delivered are separate facts: a post counts the moment it is logged (GamificationLocal) and is
// delivered when the server has answered ok for the op that carried it. This is the delivered half of SyncQueue (C9 cap):
// the LocalPost is stamped on delivery, an uploaded photo key outlives the attempt that uploaded it, the reconcile guard
// reads the queue for posts still on their way (A3, owner-directed 2026-09-08: E19 wins over 5.6.3 while undelivered post
// ops exist), and a young held op gets another chance on foreground / network return before the 24 h choice.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import SwiftData

// The two payloads that carry a post: createPost (PendingPostPayload — clientId, photoKey at the top) and patchSession
// (PatchSessionPayload — the completion post under `post`); every other key is left where it is
private struct DeliveredPostRef: Decodable {
    let clientId: String?
    let photoKey: String?
    let post: CompletionPostDTO?
}

extension SyncQueue {
    // SPEC: A3 (2026-09-08) — any createPost or patchSession op still in the queue (pending, in flight or held) is a counted
    // post the server has not seen; while one exists the server's gamification state must not replace the phone's
    func hasUndeliveredPostOps() throws -> Bool {
        let createPost = OpKind.createPost.rawValue
        let patchSession = OpKind.patchSession.rawValue
        var descriptor = FetchDescriptor<OpRecord>(predicate: #Predicate { $0.kind == createPost || $0.kind == patchSession })
        descriptor.fetchLimit = 1
        return try !store.context.fetch(descriptor).isEmpty
    }

    // SPEC: E19 · A6 (the "Sending ↻" chip ends here) — the op the server accepted carried a post: that LocalPost is delivered
    // now and, when the op went out with an uploaded photo, knows its photoKey. The sync reply carries no post id, so serverId
    // stays as it was (the next hydration or the crew stream names it).
    func markDelivered(_ record: OpRecord, now: Date) throws {
        let isCreatePost = record.kind == OpKind.createPost.rawValue
        guard isCreatePost || record.kind == OpKind.patchSession.rawValue else { return }
        let ref = try JSONDecoder.crew.decode(DeliveredPostRef.self, from: record.payload)
        let clientId = isCreatePost ? ref.clientId : ref.post?.clientId
        guard let clientId, let post = try store.post(clientId: clientId) else { return }
        post.deliveredAt = now
        if let photoKey = isCreatePost ? ref.photoKey : ref.post?.photoKey { post.photoKey = photoKey }
        try store.save()
    }

    // SPEC: E19 — the photo went up (POST photos → photoKey): the queued op now carries the key and no local path, so a retry
    // after a failed sync sends the same key instead of uploading the photo again (SyncTransport calls this mid-send)
    func attachPhotoKey(opId: String, photoKey: String) throws {
        var descriptor = FetchDescriptor<OpRecord>(predicate: #Predicate { $0.id == opId })
        descriptor.fetchLimit = 1
        guard let record = try store.context.fetch(descriptor).first, var object = try JSONSerialization.jsonObject(with: record.payload) as? [String: Any] else { return }
        object["photoKey"] = photoKey
        object.removeValue(forKey: "localPhotoPath")
        record.payload = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys, .withoutEscapingSlashes])
        try store.save()
    }

    // SPEC: A3 (2026-09-08) · E6 (reconnect → auto-send) — a held op younger than failedUploadChoiceAfterHours returns to
    // pending with a clean slate on every foreground and every network return; an older one waits for the user's choice
    // (heldOver24h → FailedUploadSheet). Returns how many were released.
    @discardableResult
    func releaseHeldForRetry(now: Date = Date()) throws -> Int {
        let held = OpState.held.rawValue
        let cutoff = now.addingTimeInterval(-TimeInterval(SpecConstants.failedUploadChoiceAfterHours * TimeUnits.secondsPerHour))
        let young = try store.context.fetch(FetchDescriptor<OpRecord>(predicate: #Predicate { $0.state == held && $0.createdAt >= cutoff }))
        for record in young {
            record.state = OpState.pending.rawValue
            record.attempts = 0
            record.nextAttemptAt = now
        }
        try store.save()
        return young.count
    }
}
