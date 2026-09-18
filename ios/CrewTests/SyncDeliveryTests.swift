// SPEC: E19 (counted vs delivered are separate facts) · A3 (2026-09-08: a young held op gets another chance before the 24 h
// choice) · A22 (2026-09-18: the completion's `post` inside patchSession is the ONE op that carries a post; a createPost record from
// an older build is not a post the queue waits for) — the delivered half of SyncQueue (SyncDelivery.swift) against an in-memory
// SwiftData container, no mocks (C4). WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class SyncDeliveryTests: XCTestCase {
    private struct Payload: Codable { let clientId: String }

    private func makeQueue(sender: @escaping (SyncOpDTO) async throws -> SyncResponseDTO) -> (SyncQueue, Store) {
        let store = Store(inMemory: true)
        return (SyncQueue(store: store, send: sender), store)
    }

    private func okResponse(for op: SyncOpDTO) -> SyncResponseDTO {
        SyncResponseDTO(results: [SyncOpResultDTO(opId: op.opId, ok: true, error: nil, retryable: nil)], gamification: nil)
    }

    private func localPost(_ clientId: String, store: Store) -> LocalPost {
        let post = LocalPost(clientId: clientId, userId: "u1", type: "cardio", sessionClientId: nil, caption: "", mealTag: nil, shareToCrew: true, dayKey: "2026-09-04", isPlannedDay: false, workoutCompleted: true, earlierToday: false, createdAt: Date(timeIntervalSince1970: 1_000_000))
        store.context.insert(post)
        return post
    }

    private func completion(_ clientId: String, when: Date) -> PatchSessionPayload {
        PatchSessionPayload(sessionId: "s1", timezone: "UTC", exercises: nil, status: "completed", completedAt: when, post: CompletionPostDTO(clientId: clientId, shareToCrew: true, caption: nil))
    }

    // A6 · E19: a workout's completion post rides inside the patchSession op — the op the server accepts stamps that LocalPost delivered
    func testACompletionPostInsideAPatchSessionOpIsStamped() async throws {
        let (queue, store) = makeQueue { op in self.okResponse(for: op) }
        let when = Date(timeIntervalSince1970: 1_000_000) // the clock the queue is stepped with: an op enqueued later than `now` is not due yet (5.6.3), so both share it
        let post = localPost("post-2", store: store)
        try queue.enqueue(.patchSession, payload: completion("post-2", when: when), now: when)
        guard case .sent = await queue.processNext(now: when) else { return XCTFail("the op is delivered") }
        XCTAssertEqual(post.deliveredAt, when)
        XCTAssertTrue(try store.pendingOps().isEmpty)
    }

    // A22: a createPost record can only come from a build older than the plate journal's removal — it is not a post the queue
    // waits for (reconcile is never blocked by it) and delivering it stamps nothing
    func testALegacyCreatePostRecordIsNeitherWaitedForNorStamped() async throws {
        let (queue, store) = makeQueue { op in self.okResponse(for: op) }
        let when = Date(timeIntervalSince1970: 1_000_000)
        let post = localPost("legacy", store: store)
        try queue.enqueue(.createPost, payload: Payload(clientId: "legacy"), now: when)
        XCTAssertFalse(try queue.hasUndeliveredPostOps())
        guard case .sent = await queue.processNext(now: when) else { return XCTFail("the op drains") }
        XCTAssertNil(post.deliveredAt)
    }

    // A3: a patchSession op still in the queue (pending, in flight or held) is an undelivered counted post
    func testUndeliveredPostOpsAreSeenInEveryState() async throws {
        let (queue, store) = makeQueue { op in self.okResponse(for: op) }
        let when = Date(timeIntervalSince1970: 1_000_000)
        XCTAssertFalse(try queue.hasUndeliveredPostOps())
        try queue.enqueue(.react, payload: Payload(clientId: "r"))
        XCTAssertFalse(try queue.hasUndeliveredPostOps()) // a reaction carries no post
        try queue.enqueue(.patchSession, payload: completion("p", when: when))
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
        try queue.enqueue(.patchSession, payload: completion("old", when: start), now: start.addingTimeInterval(-choiceAfter - 1))
        try queue.enqueue(.patchSession, payload: completion("young", when: start), now: start)
        guard case .held = await queue.processNext(now: start) else { return XCTFail("the old op is held") }
        guard case .held = await queue.processNext(now: start) else { return XCTFail("the young op is held") }
        XCTAssertTrue(try store.pendingOps().isEmpty)
        XCTAssertEqual(try queue.releaseHeldForRetry(now: start), 1)
        let released = try XCTUnwrap(store.pendingOps().first)
        XCTAssertEqual(released.attempts, 0)
        XCTAssertEqual(released.nextAttemptAt, start)
        XCTAssertEqual(try store.pendingOps().count, 1)
        XCTAssertEqual(try queue.heldOver24h(now: start).count, 1) // the old one still waits for Retry · Delete
    }
}
