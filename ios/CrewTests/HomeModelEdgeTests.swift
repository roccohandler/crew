// SPEC: T042 (Verify: unit) — the edge screens' triggers in HomeModel: welcome back at 14 quiet days and silent once answered
// (E4/S18), the stale-session prompt after a day with discard (S01), held uploads past 24 h with the user's choice (E19).
// Against an in-memory Store and a queue whose transport never sends (C4: no mocks). WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class HomeModelEdgeTests: XCTestCase {
    private let userId = "edge-user"
    private let tz = TimeZone(identifier: "America/Los_Angeles")!
    private let friday = ISO8601DateFormatter().date(from: "2026-09-04T18:00:00-07:00")!

    private func storeWithPlan() throws -> Store {
        let store = Store(inMemory: true)
        let draft = PlanGenerator.generatePlan(days: [1, 3, 5], experience: "brandNew", access: "fullGym", seed: .shared)
        try PlanLocal.replace(draft.workouts, userId: userId, updatedAt: friday, store: store)
        return store
    }

    private func queue(_ store: Store) -> SyncQueue {
        SyncQueue(store: store, send: { _ in throw AppError.invalidResponse })
    }

    func testWelcomeBackAfterFourteenQuietDaysAndSilentOnceAnswered() throws {
        let store = try storeWithPlan()
        store.context.insert(LocalPost(clientId: "old", userId: userId, type: "meal", sessionClientId: nil, caption: "eggs", mealTag: "breakfast", shareToCrew: false, dayKey: "2026-08-20", isPlannedDay: false, workoutCompleted: false, earlierToday: false, createdAt: friday.addingTimeInterval(-15 * TimeInterval(TimeUnits.secondsPerDay))))
        try store.save()
        let model = HomeModel(store: store, userId: userId, timeZone: tz, syncQueue: queue(store), welcomeBackAckDay: nil)
        model.refresh(now: friday) // 15 quiet days
        XCTAssertTrue(model.welcomeBack)
        XCTAssertTrue(model.hasPlan)
        let answered = HomeModel(store: store, userId: userId, timeZone: tz, syncQueue: queue(store), welcomeBackAckDay: "2026-09-04")
        answered.refresh(now: friday)
        XCTAssertFalse(answered.welcomeBack)
    }

    func testNoWelcomeBackForABridgeUser() throws {
        let store = try storeWithPlan()
        let model = HomeModel(store: store, userId: userId, timeZone: tz, syncQueue: queue(store), welcomeBackAckDay: nil)
        model.refresh(now: friday)
        XCTAssertFalse(model.welcomeBack)
        XCTAssertEqual(model.today, .bridge(.workout))
    }

    func testStaleSessionPromptAfterADayAndDiscard() throws {
        let store = try storeWithPlan()
        let workout = try XCTUnwrap(store.plan(for: userId)?.workouts.first { $0.weekday == 5 })
        let limit = TimeInterval(SpecConstants.staleInProgressSessionAfterHours * TimeUnits.secondsPerHour)
        _ = try SessionActions.startSession(from: workout, userId: userId, timeZone: tz, now: friday.addingTimeInterval(-limit - 1), store: store)
        let model = HomeModel(store: store, userId: userId, timeZone: tz, syncQueue: queue(store), welcomeBackAckDay: nil)
        model.refresh(now: friday)
        XCTAssertNotNil(model.staleSession)
        XCTAssertNotNil(model.resumeSession)
        model.discardStaleSession(now: friday)
        XCTAssertNil(model.staleSession)
        XCTAssertNil(try store.openSession(for: userId))
        XCTAssertEqual(try store.gamificationState(for: userId).totalXP, 0) // nothing counted, nothing lost
    }

    func testFreshSessionIsNotStale() throws {
        let store = try storeWithPlan()
        let workout = try XCTUnwrap(store.plan(for: userId)?.workouts.first { $0.weekday == 5 })
        _ = try SessionActions.startSession(from: workout, userId: userId, timeZone: tz, now: friday.addingTimeInterval(-TimeInterval(TimeUnits.secondsPerHour)), store: store)
        let model = HomeModel(store: store, userId: userId, timeZone: tz, syncQueue: queue(store), welcomeBackAckDay: nil)
        model.refresh(now: friday)
        XCTAssertNil(model.staleSession)
        XCTAssertNotNil(model.resumeSession)
    }

    func testHeldUploadsSurfaceAfterTwentyFourHoursAndResolve() throws {
        let store = try storeWithPlan()
        let age = TimeInterval((SpecConstants.failedUploadChoiceAfterHours + 1) * TimeUnits.secondsPerHour)
        let record = OpRecord(id: "held-1", kind: .createPost, payload: Data("{}".utf8), createdAt: friday.addingTimeInterval(-age))
        record.state = OpState.held.rawValue
        store.context.insert(record)
        try store.save()
        let model = HomeModel(store: store, userId: userId, timeZone: tz, syncQueue: queue(store), welcomeBackAckDay: nil)
        model.refresh(now: friday)
        XCTAssertEqual(model.heldUploads.map(\.id), ["held-1"])
        model.resolveUpload(record, choice: .delete, now: friday)
        XCTAssertTrue(model.heldUploads.isEmpty)
    }
}
