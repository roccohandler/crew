// SPEC: 1C/1D (a reinstalled phone wakes signed in with an empty Store and must not show the bridge to a veteran) · E6 · 5.6.3 ·
// A1/A2/A6 (2026-09-08: a session arrives with its kind and set distances, a post with its summary line) — the local writers of
// ServerHydrate against an in-memory SwiftData container, no mocks (C4); the network half is the Mac pass (journey ② launches
// through it). WRITTEN — UNVERIFIED (needs Mac). T024 / T035 / T042

import XCTest
@testable import Crew

@MainActor
final class ServerHydrateTests: XCTestCase {
    private let userId = "hydrate-user"
    private let when = ISO8601DateFormatter().date(from: "2026-09-04T18:00:00Z")!

    private func post(_ id: String, clientId: String? = nil, summary: String? = nil) -> PostDTO {
        PostDTO(id: id, clientId: clientId, type: summary == nil ? "meal" : "workout", sessionId: nil, photoKey: nil, caption: "oats", mealTag: summary == nil ? "breakfast" : nil, crewId: "crew-1", dayKey: "2026-09-03", isPlannedDay: false, workoutCompleted: summary != nil, earlierToday: false, summary: summary, createdAt: when)
    }

    private func session(_ clientId: String, workoutName: String, workoutKind: String?, exercise: SessionExerciseDTO) -> SessionDTO {
        SessionDTO(id: "server-\(clientId)", clientId: clientId, dayKey: "2026-09-04", status: "completed", workoutName: workoutName, workoutKind: workoutKind, isPlannedDay: workoutKind != "cardio", startedAt: when, completedAt: when, timezone: "UTC", exercises: [exercise], updatedAt: when)
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
        XCTAssertNil(first.summary)
        XCTAssertNotNil(try store.post(clientId: "p2")) // no clientId on the wire → the server id stands in
        let home = HomeModel(store: store, userId: userId, timeZone: TimeZone(identifier: "UTC")!)
        home.refresh(now: when)
        XCTAssertEqual(home.today, .rest(posted: false)) // 1D: the journal exists, so the bridge is gone; no plan yet → a rest day
    }

    // A6: the line the server wrote at completion arrives with the post
    func testAWorkoutPostArrivesWithItsSummaryLine() throws {
        let store = Store(inMemory: true)
        try ServerHydrate.writeJournal([post("p3", clientId: "c3", summary: "Push day · 12/12 sets · 44 min")], userId: userId, store: store)
        XCTAssertEqual(try XCTUnwrap(store.post(clientId: "c3")).summary, "Push day · 12/12 sets · 44 min")
    }

    func testSessionsArriveWithTheirSnapshotsAndCountToday() throws {
        let store = Store(inMemory: true)
        let set = SetLogDTO(targetReps: 10, actualReps: 10, weight: nil, holdSeconds: nil, distanceMeters: nil, isWarmup: false, done: true)
        let exercise = SessionExerciseDTO(exerciseId: "push-up", name: "Push-Up", equipment: "bodyweight", type: "strength", targetSets: 1, targetReps: 10, holdSeconds: nil, order: 0, skipped: false, sets: [set])
        let item = session("sc1", workoutName: "Push day", workoutKind: "push", exercise: exercise)
        try ServerHydrate.writeSessions([item, item], userId: userId, store: store)
        XCTAssertEqual(try store.sessions(for: userId, dayKey: "2026-09-04").count, 1)
        let local = try XCTUnwrap(store.session(clientId: "sc1"))
        XCTAssertEqual(local.status, "completed")
        XCTAssertEqual(local.completedAt, when)
        XCTAssertEqual(local.workoutKind, "push")
        XCTAssertEqual(local.exercises.first?.sets.first?.done, true)
        XCTAssertEqual(local.exercises.first?.sets.first?.asPlanned, true)
        XCTAssertEqual(try store.lastCompletedRotationKind(for: userId, cycle: ["push", "pull", "legs"]), "push") // A1: the pointer reads the hydrated kind
    }

    // A2: a cardio log arrives with its kind and distance; A1: it never moves the rotation pointer
    func testACardioLogArrivesWithItsDistanceAndStaysOutsideTheRotation() throws {
        let store = Store(inMemory: true)
        let set = SetLogDTO(targetReps: 0, actualReps: 0, weight: nil, holdSeconds: 1500, distanceMeters: 2100, isWarmup: false, done: true)
        let exercise = SessionExerciseDTO(exerciseId: "walk", name: "Walk", equipment: "bodyweight", type: "cardio", targetSets: 1, targetReps: 0, holdSeconds: 1500, order: 0, skipped: false, sets: [set])
        try ServerHydrate.writeSessions([session("sc2", workoutName: "Walk", workoutKind: "cardio", exercise: exercise)], userId: userId, store: store)
        let local = try XCTUnwrap(store.session(clientId: "sc2"))
        XCTAssertEqual(local.workoutKind, "cardio")
        XCTAssertFalse(local.isPlannedDay)
        XCTAssertEqual(local.exercises.first?.sets.first?.distanceMeters, 2100)
        XCTAssertNil(try store.lastCompletedRotationKind(for: userId, cycle: ["push", "pull", "legs"]))
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
