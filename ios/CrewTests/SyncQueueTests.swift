// SPEC: T014 (Verify: ios unit suite) · 8.3 SyncQueue: retry/backoff, poison-message handling, ordering — against an
// in-memory SwiftData container, no mocks (C4). The sender is a test-provided plain function. WRITTEN — UNVERIFIED.

import XCTest
@testable import Crew

@MainActor
final class SyncQueueTests: XCTestCase {
    private struct Payload: Codable { let clientId: String }

    private func makeQueue(sender: @escaping (SyncOpDTO) async throws -> SyncResponseDTO) -> (SyncQueue, Store) {
        let store = Store(inMemory: true)
        return (SyncQueue(store: store, send: sender), store)
    }

    private func okResponse(for op: SyncOpDTO) -> SyncResponseDTO {
        SyncResponseDTO(results: [SyncOpResultDTO(opId: op.opId, ok: true, error: nil, retryable: nil)], gamification: nil)
    }

    func testOpsAreSentInFifoOrder() async throws {
        var sentKinds: [String] = []
        let (queue, _) = makeQueue { op in sentKinds.append(op.kind); return self.okResponse(for: op) }
        try queue.enqueue(.createSession, payload: Payload(clientId: "a"))
        try queue.enqueue(.patchSession, payload: Payload(clientId: "a"))
        try queue.enqueue(.createPost, payload: Payload(clientId: "b"))
        for _ in 0..<3 { _ = await queue.processNext() }
        XCTAssertEqual(sentKinds, ["createSession", "patchSession", "createPost"])
        let afterAll = await queue.processNext() // an await cannot sit inside XCTAssert's autoclosure
        XCTAssertEqual(afterAll, .idle)
    }

    func testBackoffFollowsTheSpecScheduleThenHolds() async throws {
        let (queue, store) = makeQueue { _ in throw AppError.server(code: "unavailable", message: "later", status: HttpStatus.serviceUnavailable) }
        let start = Date(timeIntervalSince1970: 1_000_000)
        try queue.enqueue(.createPost, payload: Payload(clientId: "c"), now: start)
        var now = start
        for attempt in 1..<SpecConstants.syncMaxAttemptsBeforeHeld {
            let outcome = await queue.processNext(now: now)
            XCTAssertEqual(outcome, .retryScheduled(opId: try XCTUnwrap(store.pendingOps().first?.id), attempt: attempt))
            let record = try XCTUnwrap(store.pendingOps().first)
            XCTAssertEqual(record.nextAttemptAt.timeIntervalSince(now), TimeInterval(SpecConstants.syncBackoffSeconds[attempt - 1]))
            let notDueYet = await queue.processNext(now: now)
            XCTAssertEqual(notDueYet, .waiting(until: record.nextAttemptAt)) // not due yet — and nothing overtakes it
            now = record.nextAttemptAt
        }
        let lastOutcome = await queue.processNext(now: now)
        guard case .held = lastOutcome else { return XCTFail("expected held after \(SpecConstants.syncMaxAttemptsBeforeHeld) attempts, got \(lastOutcome)") }
        XCTAssertTrue(try store.pendingOps().isEmpty)
    }

    func testPoisonOpIsHeldImmediatelyAndDoesNotBlockTheLine() async throws {
        var calls = 0
        let (queue, store) = makeQueue { op in
            calls += 1
            if op.kind == OpKind.putPlan.rawValue { throw AppError.server(code: "validation", message: "bad plan", status: HttpStatus.badRequest) }
            return self.okResponse(for: op)
        }
        try queue.enqueue(.putPlan, payload: Payload(clientId: "poison"))
        try queue.enqueue(.createPost, payload: Payload(clientId: "fine"))
        guard case .held = await queue.processNext() else { return XCTFail("poison op should be held") }
        guard case .sent = await queue.processNext() else { return XCTFail("the next op should still go out") }
        XCTAssertEqual(calls, 2)
        XCTAssertTrue(try store.pendingOps().isEmpty)
    }

    func testReconcileReplacesLocalGamificationState() async throws {
        let server = GamificationStateDTO(currentStreak: 13, longestStreak: 21, totalXP: 1525, level: 3, shields: 1, lastCountedDayKey: "2026-09-04", earnedAchievementIds: ["first-flame"])
        let (queue, store) = makeQueue { op in SyncResponseDTO(results: [SyncOpResultDTO(opId: op.opId, ok: true, error: nil, retryable: nil)], gamification: server) }
        AuthStore.shared.store(AuthSessionDTO(user: UserDTO(id: "u1", email: "u@example.com", authProvider: "email", displayName: "U", profilePhotoKey: nil, units: "lb", timezone: "UTC", reminderTime: nil, welcomeBackAckDay: nil, createdAt: Date()), accessToken: "a", refreshToken: "r", accessExpiresAt: Date().addingTimeInterval(TimeInterval(SpecConstants.tokenRefreshLeadSeconds))))
        let local = try store.gamificationState(for: "u1")
        local.currentStreak = 99
        try queue.enqueue(.createPost, payload: Payload(clientId: "d"))
        _ = await queue.processNext()
        XCTAssertEqual(local.currentStreak, 13)
        XCTAssertEqual(local.totalXP, 1525)
        XCTAssertEqual(local.earnedAchievementIds, ["first-flame"])
        AuthStore.shared.signOutLocally()
    }

    // E6: offline is not a failed attempt — the op waits untouched and goes out the moment the network is back
    func testOfflineLeavesTheOpWaitingWithoutCountingAnAttempt() async throws {
        var online = false
        let (queue, store) = makeQueue { op in
            guard online else { throw AppError.offline }
            return self.okResponse(for: op)
        }
        let start = Date(timeIntervalSince1970: 1_000_000)
        try queue.enqueue(.createPost, payload: Payload(clientId: "e"), now: start)
        let whileOffline = await queue.processNext(now: start)
        XCTAssertEqual(whileOffline, .offline)
        let record = try XCTUnwrap(store.pendingOps().first)
        XCTAssertEqual(record.attempts, 0)
        XCTAssertEqual(record.nextAttemptAt, start)
        online = true
        guard case .sent = await queue.processNext(now: start) else { return XCTFail("the op goes out as soon as the network is back") }
    }

    // 1C: a dead session is not the op's fault — nothing is counted, nothing is held; the next sign-in sends it
    func testASignedOutPhoneKeepsItsOpsUntouched() async throws {
        let (queue, store) = makeQueue { _ in throw AppError.unauthorized }
        let start = Date(timeIntervalSince1970: 1_000_000)
        try queue.enqueue(.react, payload: Payload(clientId: "j"), now: start)
        let outcome = await queue.processNext(now: start)
        XCTAssertEqual(outcome, .signedOut)
        let record = try XCTUnwrap(store.pendingOps().first)
        XCTAssertEqual(record.attempts, 0)
        XCTAssertEqual(record.state, OpState.pending.rawValue)
    }

    // 8.3 ordering: a backoff on the head holds the line — patchSession never overtakes the createSession it depends on
    func testABackoffOnTheHeadHoldsTheLine() async throws {
        var sent: [String] = []
        var failFirst = true
        let (queue, store) = makeQueue { op in
            if failFirst, op.kind == OpKind.createSession.rawValue { failFirst = false; throw AppError.server(code: "unavailable", message: "later", status: HttpStatus.serviceUnavailable) }
            sent.append(op.kind)
            return self.okResponse(for: op)
        }
        let start = Date(timeIntervalSince1970: 1_000_000)
        try queue.enqueue(.createSession, payload: Payload(clientId: "f"), now: start)
        try queue.enqueue(.patchSession, payload: Payload(clientId: "f"), now: start.addingTimeInterval(0.1))
        guard case .retryScheduled = await queue.processNext(now: start.addingTimeInterval(0.1)) else { return XCTFail("the head backs off") }
        let head = try XCTUnwrap(store.pendingOps().first)
        let blocked = await queue.processNext(now: start.addingTimeInterval(0.5)) // patchSession is due by now; the head is not
        XCTAssertEqual(blocked, .waiting(until: head.nextAttemptAt))
        _ = await queue.processNext(now: head.nextAttemptAt)
        _ = await queue.processNext(now: head.nextAttemptAt)
        XCTAssertEqual(sent, ["createSession", "patchSession"])
    }

    func testDrainSendsEverythingInOrderThenStops() async throws {
        var sent: [String] = []
        let (queue, store) = makeQueue { op in sent.append(op.kind); return self.okResponse(for: op) }
        try queue.enqueue(.createSession, payload: Payload(clientId: "g"))
        try queue.enqueue(.patchSession, payload: Payload(clientId: "g"))
        try queue.enqueue(.react, payload: Payload(clientId: "h"))
        await queue.drain()
        XCTAssertEqual(sent, ["createSession", "patchSession", "react"])
        XCTAssertTrue(try store.pendingOps().isEmpty)
        XCTAssertFalse(queue.isDraining)
    }

    // 8.6 kill mid-queue → nothing lost
    func testAnOpLeftInFlightByAKillIsRecoveredAtLaunch() async throws {
        let (queue, store) = makeQueue { op in self.okResponse(for: op) }
        try queue.enqueue(.createPost, payload: Payload(clientId: "i"))
        let record = try XCTUnwrap(store.pendingOps().first)
        record.state = OpState.inFlight.rawValue // the app died between send and reply
        try store.save()
        XCTAssertTrue(try store.pendingOps().isEmpty)
        try queue.recoverInFlight()
        XCTAssertEqual(try store.pendingOps().count, 1)
        guard case .sent = await queue.processNext() else { return XCTFail("the recovered op goes out") }
    }
}
