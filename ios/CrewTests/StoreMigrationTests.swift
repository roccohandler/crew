// SPEC: W9 (owner order 2026-09-18, item 6) · StoreSchema.swift — the update a TestFlight tester actually goes through: a store FILE
// written by build 150's schema (CrewSchemaV1: a plate-journal-era post with its four legacy properties, no nutrition entities) is
// opened by today's Store under CrewMigrationPlan, and the phone keeps its rows — the plan, the journal line and the queued op are all
// still there, the legacy properties are gone, and the four nutrition entities exist and are empty. If the lightweight stage ever stops
// being lightweight, Store.init's F31 path starts the store over and THIS TEST GOES RED, which is the point: a lossy update must be a
// decision, never an accident. Real SQLite file in the temp directory, no mocks (C4). This file is NOT in ios/Package.swift.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftData
import XCTest
@testable import Crew

@MainActor
final class StoreMigrationTests: XCTestCase {
    private var url: URL!

    override func setUp() {
        url = FileManager.default.temporaryDirectory.appendingPathComponent("crew-migration-\(UUID().uuidString).store")
    }

    override func tearDown() {
        for suffix in ["", "-shm", "-wal"] { try? FileManager.default.removeItem(atPath: url.path + suffix) }
    }

    // Build 150's store, written the way build 150 wrote it: a plain Schema over the eleven models, NO versioned schema and NO plan
    // (Store.init at 016721f) — so the test proves the plan recognises an unversioned store, which is every tester's phone today
    private func writeBuild150Store() throws {
        let container = try ModelContainer(for: Schema(CrewSchemaV1.models), configurations: [ModelConfiguration(url: url)])
        let context = ModelContext(container)
        let dinner = CrewSchemaV1.LocalPost(clientId: "legacy-post", userId: "u1", type: "meal", caption: "Dinner", shareToCrew: false, dayKey: "2026-09-04", isPlannedDay: false, workoutCompleted: false, earlierToday: true, createdAt: Date())
        dinner.mealTag = "dinner"
        dinner.photoKey = "photos/u1/legacy.jpg"
        context.insert(dinner)
        context.insert(LocalPlan(userId: "u1", trainingWeekdays: [1, 3, 5], updatedAt: Date(), workouts: []))
        context.insert(OpRecord(id: "queued-op", kind: .patchSession, payload: Data("{}".utf8), createdAt: Date()))
        try context.save()
    }

    func testABuild150StoreOpensUnderThePlanAndKeepsItsRows() throws {
        try writeBuild150Store()
        let store = Store(inMemory: false, url: url)
        XCTAssertEqual(try store.allPosts(for: "u1").map(\.caption), ["Dinner"], "the journal did not survive the update — F31 started the store over, so the V1 → V2 stage is not lightweight any more")
        XCTAssertEqual(try store.plan(for: "u1")?.trainingWeekdays, [1, 3, 5])
        XCTAssertEqual(try store.pendingOps().map(\.id), ["queued-op"], "a queued op must outlive an update (8.6: nothing lost)")
        XCTAssertNil(try NutritionLocal.targets(for: "u1", store: store)) // the four new entities exist, and are empty
        XCTAssertTrue(try NutritionLocal.meals(for: "u1", store: store).isEmpty)
    }

    // Build 202's store, written the way it wrote it: CrewSchemaV2, the versioned schema of builds up to 202
    private func writeBuild202Store() throws {
        let container = try ModelContainer(for: Schema(versionedSchema: CrewSchemaV2.self), configurations: [ModelConfiguration(url: url)])
        let context = ModelContext(container)
        context.insert(LocalPlan(userId: "u1", trainingWeekdays: [1, 3, 5], updatedAt: Date(), workouts: []))
        context.insert(OpRecord(id: "queued-op", kind: .putPlan, payload: Data("{}".utf8), createdAt: Date()))
        try context.save()
    }

    // SPEC: A27 (a) — V2 → V3 adds the training-days history and touches nothing else: the plan and the queued op survive, and the
    // history starts empty, so the plan's own days stand in for it until they next change
    func testABuild202StoreOpensAtV3AndKeepsItsRows() throws {
        try writeBuild202Store()
        let store = Store(inMemory: false, url: url)
        XCTAssertEqual(try store.plan(for: "u1")?.trainingWeekdays, [1, 3, 5], "the plan did not survive the update — F31 started the store over, so the V2 → V3 stage is not lightweight any more")
        XCTAssertEqual(try store.pendingOps().map(\.id), ["queued-op"], "a queued op must outlive an update (8.6: nothing lost)")
        XCTAssertEqual(try PlanLocal.trainingDays(for: "u1", store: store).map(\.weekdays), [[1, 3, 5]])
    }

    // A fresh install has no file at all: the plan has nothing to migrate and the store opens at the current version
    func testAFreshStoreOpensAtTheCurrentVersion() throws {
        let store = Store(inMemory: false, url: url)
        store.context.insert(LocalPost(clientId: "p1", userId: "u1", type: "workout", sessionClientId: nil, caption: "", shareToCrew: false, dayKey: "2026-09-18", isPlannedDay: true, workoutCompleted: true, createdAt: Date()))
        try store.save()
        XCTAssertEqual(try store.allPosts(for: "u1").count, 1)
    }
}
