// SPEC: C5 (duplicate on the second occurrence, extract on the THIRD) — three Home test classes now build the same
// in-memory Store with the same Mon/Wed/Fri plan at the same instant: HomeModelTests, HomeModelEdgeTests and
// HomeModelFactsTests. This is that third occurrence, extracted into plain functions and nothing else — no base
// class, no protocol, no builder (C1–C4). Each class keeps its own userId, because a shared one would let a leftover
// row in one suite explain a pass in another.
//
// A1: every generated plan is Push day → Pull day → Leg day in stored order, at any frequency.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import XCTest
@testable import Crew

enum HomeTestFixtures {
    // Friday 2026-09-04, 18:00 UTC-7 — a training day in the Mon/Wed/Fri plan, inside the week Mon 2026-08-31 … Sun 2026-09-06
    static let friday = ISO8601DateFormatter().date(from: "2026-09-04T18:00:00-07:00")!
    static let timeZone = TimeZone(identifier: "America/Los_Angeles")!

    @MainActor
    static func storeWithPlan(userId: String, days: Set<Int> = [1, 3, 5], now: Date = friday) throws -> Store {
        let store = Store(inMemory: true)
        let draft = PlanGenerator.generatePlan(days: days, experience: "brandNew", access: "fullGym", seed: .shared)
        try PlanLocal.replace(draft, userId: userId, updatedAt: now, store: store)
        return store
    }

    // A post is what ends the BRIDGE (§1D), so every non-bridge test needs one before it can assert a real state
    @MainActor
    static func post(_ store: Store, userId: String, id: String, dayKey: String, now: Date = friday) throws {
        store.context.insert(LocalPost(clientId: id, userId: userId, type: "meal", sessionClientId: nil, caption: "eggs", mealTag: "breakfast", shareToCrew: false, dayKey: dayKey, isPlannedDay: false, workoutCompleted: false, earlierToday: false, createdAt: now))
        try store.save()
    }
}
