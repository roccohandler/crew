// SPEC: E19 (counted vs delivered are separate facts) · A3 (2026-09-08: a young held op gets another chance before the 24 h
// choice) — the delivered half of SyncQueue (SyncDelivery.swift) against an in-memory SwiftData container, no mocks (C4).
// WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class SyncDeliveryTests: XCTestCase {
    private struct Payload: Codable { let clientId: String }
    private struct PhotoPayload: Codable { let clientId: String; let localPhotoPath: String?; let photoKey: String? }

    private func makeQueue(sender: @escaping (SyncOpDTO) async throws -> SyncResponseDTO) -> (SyncQueue, Store) {
        let store = Store(inMemory: true)
        return (SyncQueue(store: store, send: sender), store)
    }

    private func okResponse(for op: SyncOpDTO) -> SyncResponseDTO {
        SyncResponseDTO(results: [SyncOpResultDTO(opId: op.opId, ok: true, error: nil, retryable: nil)], gamification: nil)
    }

    private func localPost(_ clientId: String, store: Store) -> LocalPost {
        let post = LocalPost(clientId: clientId, userId: "u1", type: "meal", sessionClientId: nil, caption: "oats", mealTag: "breakfast", shareToCrew: true, dayKey: "2026-09-04", isPlannedDay: false, workoutCompleted: false, earlierToday: false, createdAt: Date())
        store.context.insert(post)
        return post
    }

    // E19: the op the server accepted carried a post — that LocalPost is delivered now, with the key its photo went up under; the
    // queued payload keeps the key and drops the local path (what SyncTransport does after POST photos), so a retry never re-uploads
    func testADeliveredPostIsStampedWithItsPhotoKey() async throws {
        let (queue, store) = makeQueue { op in self.okResponse(for: op) }
        let post = localPost("post-1", store: store)
        post.localPhotoPath = "/outbox/post-1.jpg"
        try queue.enqueue(.createPost, payload: PhotoPayload(clientId: "post-1", localPhotoPath: "/outbox/post-1.jpg", photoKey: nil))
        let record = try XCTUnwrap(store.pendingOps().first)
        try queue.attachPhotoKey(opId: record.id, photoKey: "blob/abc")
        let payload = String(decoding: record.payload, as: UTF8.self)
        XCTAssertTrue(payload.contains("blob/abc"))
        XCTAssertFalse(payload.contains("localPhotoPath"))
        let when = Date(timeIntervalSince1970: 1_000_000)
        guard case .sent = await queue.processNext(now: when) else { return XCTFail("the op is delivered") }
        XCTAssertEqual(post.deliveredAt, when)
        XCTAssertEqual(post.photoKey, "blob/abc")
        XCTAssertTrue(try store.pendingOps().isEmpty)
    }

    // A6: a workout's completion post rides inside the patchSession op — it is stamped delivered the same way
    func testACompletionPostInsideAPatchSessionOpIsStamped() async throws {
        let (queue, store) = makeQueue { op in self.okResponse(for: op) }
        let post = localPost("post-2", store: store)
        let payload = PatchSessionPayload(sessionId: "s1", timezone: "UTC", exercises: nil, status: "completed", completedAt: Date(), post: CompletionPostDTO(clientId: "post-2", shareToCrew: true, caption: nil, photoKey: nil))
        try queue.enqueue(.patchSession, payload: payload)
        let when = Date(timeIntervalSince1970: 1_000_000)
        guard case .sent = await queue.processNext(now: when) else { return XCTFail("the op is delivered") }
        XCTAssertEqual(post.deliveredAt, when)
        XCTAssertNil(post.photoKey)
    }

    // A3: any createPost or patchSession op still in the queue (pending, in flight or held) is an undelivered counted post
    func testUndeliveredPostOpsAreSeenInEveryState() async throws {
        let (queue, store) = makeQueue { op in self.okResponse(for: op) }
        XCTAssertFalse(try queue.hasUndeliveredPostOps())
        try queue.enqueue(.react, payload: Payload(clientId: "r"))
        XCTAssertFalse(try queue.hasUndeliveredPostOps()) // a reaction carries no post
        try queue.enqueue(.createPost, payload: Payload(clientId: "p"))
        XCTAssertTrue(try queue.hasUndeliveredPostOps())
        let record = try XCTUnwrap(store.pendingOps().last)
        record.state = OpState.held.rawValue
        try store.save()
        XCTAssertTrue(try queue.hasUndeliveredPostOps())
        record.state = OpState.inFlight.rawValue
        try store.save()
        XCTAssertTrue(try queue.hasUndeliveredPostOps())
    }

    // A3: a young held op returns to pending on foreground / network return; one past the 24 h choice waits for the user (E19)
    func testAYoungHeldOpIsReleasedForRetryAndAnOldOneWaits() async throws {
        let (queue, store) = makeQueue { _ in throw AppError.server(code: "validation", message: "no", status: HttpStatus.badRequest) }
        let start = Date(timeIntervalSince1970: 1_000_000)
        let choiceAfter = TimeInterval(SpecConstants.failedUploadChoiceAfterHours * TimeUnits.secondsPerHour)
        try queue.enqueue(.createPost, payload: Payload(clientId: "old"), now: start.addingTimeInterval(-choiceAfter - 1))
        try queue.enqueue(.createPost, payload: Payload(clientId: "young"), now: start)
        guard case .held = await queue.processNext(now: start) else { return XCTFail("the old op is held") }
        guard case .held = await queue.processNext(now: start) else { return XCTFail("the young op is held") }
        XCTAssertTrue(try store.pendingOps().isEmpty)
        XCTAssertEqual(try queue.releaseHeldForRetry(now: start), 1)
        let released = try XCTUnwrap(store.pendingOps().first)
        XCTAssertEqual(released.attempts, 0)
        XCTAssertEqual(released.nextAttemptAt, start)
        XCTAssertEqual(try store.pendingOps().count, 1)
        XCTAssertEqual(try queue.heldOver24h(now: start).count, 1) // the old one still waits for Retry · Post without photo · Delete
    }
}
