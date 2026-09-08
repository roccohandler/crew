// SPEC: 1C/1D (a reinstalled phone wakes signed in with an empty Store and must not show the bridge to a veteran) · E6 · 5.6.3 —
// the local writers of ServerHydrate against an in-memory SwiftData container, no mocks (C4); the network half is the Mac
// pass (journey ② launches through it). WRITTEN — UNVERIFIED (needs Mac). T024 / T035 / T042

import XCTest
@testable import Crew

@MainActor
final class ServerHydrateTests: XCTestCase {
    private let userId = "hydrate-user"
    private let when = ISO8601DateFormatter().date(from: "2026-09-04T18:00:00Z")!

    private func post(_ id: String, clientId: String? = nil) -> PostDTO {
        PostDTO(id: id, clientId: clientId, type: "meal", sessionId: nil, photoKey: nil, caption: "oats", mealTag: "breakfast", crewId: "crew-1", dayKey: "2026-09-03", isPlannedDay: false, workoutCompleted: false, earlierToday: false, createdAt: when)
    }

    func testEmptyMeansNeitherAPlanNorAPost() throws {
        let store = Store(inMemory: true)
        XCTAssertTrue(ServerHydrate.isEmpty(userId: userId, store: store))
        try ServerHydrate.writeJournal([post("p1")], userId: userId, store: store)
        XCTAssertFalse(ServerHydrate.isEmpty(userId: userId, store: store))
    }

    func testJournalRowsAreWrittenOnceAndAlreadyDelivered() throws {
        let store = Store(inMemory: true)
        try ServerHydrate.writeJournal([post("p1", clientId: "c1"), post("p2")], userId: userId, store: store)
        try ServerHydrate.writeJournal([post("p1", clientId: "c1"), post("p2")], userId: userId, store: store)
        XCTAssertEqual(try store.allPosts(for: userId).count, 2)
        let first = try XCTUnwrap(store.post(clientId: "c1"))
        XCTAssertEqual(first.serverId, "p1")
        XCTAssertEqual(first.deliveredAt, when)
        XCTAssertTrue(first.shareToCrew)
        XCTAssertNotNil(try store.post(clientId: "p2")) // no clientId on the wire → the server id stands in
        let home = HomeModel(store: store, userId: userId, timeZone: TimeZone(identifier: "UTC")!)
        home.refresh(now: when)
        XCTAssertEqual(home.today, .rest(posted: false)) // 1D: the journal exists, so the bridge is gone; no plan yet → a rest day
    }

    func testSessionsArriveWithTheirSnapshotsAndCountToday() throws {
        let store = Store(inMemory: true)
        let set = SetLogDTO(targetReps: 10, actualReps: 10, weight: nil, holdSeconds: nil, isWarmup: false, done: true)
        let exercise = SessionExerciseDTO(exerciseId: "push-up", name: "Push-Up", equipment: "bodyweight", type: "strength", targetSets: 1, targetReps: 10, holdSeconds: nil, order: 0, skipped: false, sets: [set])
        let session = SessionDTO(id: "s1", clientId: "sc1", dayKey: "2026-09-04", status: "completed", workoutName: "Push day", isPlannedDay: true, startedAt: when, completedAt: when, timezone: "UTC", exercises: [exercise], updatedAt: when)
        try ServerHydrate.writeSessions([session, session], userId: userId, store: store)
        XCTAssertEqual(try store.sessions(for: userId, dayKey: "2026-09-04").count, 1)
        let local = try XCTUnwrap(store.session(clientId: "sc1"))
        XCTAssertEqual(local.status, "completed")
        XCTAssertEqual(local.completedAt, when)
        XCTAssertEqual(local.exercises.first?.sets.first?.done, true)
        XCTAssertEqual(local.exercises.first?.sets.first?.asPlanned, true)
    }

    func testGamificationIsReplacedByTheServer() throws {
        let store = Store(inMemory: true)
        let local = try store.gamificationState(for: userId)
        local.currentStreak = 4
        try ServerHydrate.replaceGamification(GamificationStateDTO(currentStreak: 12, longestStreak: 20, totalXP: 1300, level: 2, shields: 2, lastCountedDayKey: "2026-09-03", earnedAchievementIds: ["first-flame"]), userId: userId, store: store)
        XCTAssertEqual(local.currentStreak, 12)
        XCTAssertEqual(local.shields, 2)
        XCTAssertEqual(local.earnedAchievementIds, ["first-flame"])
    }
}
