// SPEC: E19 — counted vs delivered are separate facts: a post counts the moment it is logged (GamificationLocal) and is
// delivered when the server has answered ok for the op that carried it. This is the delivered half of SyncQueue (C9 cap):
// the LocalPost is stamped on delivery, the reconcile guard reads the queue for posts still on their way (A3, owner-directed
// 2026-09-08: E19 wins over 5.6.3 while undelivered post ops exist), and a young held op gets another chance on foreground /
// network return before the 24 h choice. A22 (owner-approved 2026-09-18): the only op that carries a post is patchSession (the
// completion's `post`); createPost is retired with the plate journal — a record of that kind from an older build still drains,
// the server answers postsRetired (non-retryable), the queue holds it for the user's Retry · Delete, and it never blocks a
// reconcile. WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import SwiftData

// The payload that carries a post: patchSession (PatchSessionPayload — the completion post under `post`)
private struct DeliveredPostRef: Decodable {
    let post: CompletionPostDTO?
}

extension SyncQueue {
    // SPEC: A3 (2026-09-08) — a patchSession op still in the queue (pending, in flight or held) may carry a counted post the server
    // has not seen; while one exists the server's gamification state must not replace the phone's
    func hasUndeliveredPostOps() throws -> Bool {
        let patchSession = OpKind.patchSession.rawValue
        var descriptor = FetchDescriptor<OpRecord>(predicate: #Predicate { $0.kind == patchSession })
        descriptor.fetchLimit = 1
        return try !store.context.fetch(descriptor).isEmpty
    }

    // SPEC: E19 · A6 (the "Sending ↻" chip ends here) — the op the server accepted carried a post: that LocalPost is delivered now.
    // The sync reply carries no post id, so serverId stays as it was (the next hydration or the crew stream names it).
    func markDelivered(_ record: OpRecord, now: Date) throws {
        guard record.kind == OpKind.patchSession.rawValue else { return }
        let ref = try JSONDecoder.crew.decode(DeliveredPostRef.self, from: record.payload)
        guard let clientId = ref.post?.clientId, let post = try store.post(clientId: clientId) else { return }
        post.deliveredAt = now
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
