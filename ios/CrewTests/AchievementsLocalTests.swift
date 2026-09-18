// SPEC: E8 on the phone — the unlock rides a completion: the first workout carries first-flame + showed-up in its awards,
// after the XP and streak awards, and never again (V46). The threshold rules themselves are V45–V50 (VectorRunnerTests) and
// the counter derivations are AchievementsTests; this file is the SwiftData half, so it lives in the Xcode target only —
// the SwiftPM engine package (ios/Package.swift) cannot build SwiftData on Linux. WRITTEN — UNVERIFIED (needs Mac). T026

import XCTest
@testable import Crew

@MainActor
final class AchievementsLocalTests: XCTestCase {
    func testFirstCompletionUnlocksFirstFlameAndShowedUpLocally() throws {
        let store = Store(inMemory: true)
        let userId = "achiever"
        let draft = PlanGenerator.generatePlan(days: [1, 3, 5], experience: "brandNew", seed: .shared)
        try PlanLocal.replace(draft, userId: userId, updatedAt: Date(), store: store)
        // A1 — pinned by kind: a SwiftData to-many has no order (NextUpLine.swift:75), and `again` below must
        // quick-complete the SAME workout for the "first-flame fires once" assertion to mean anything.
        let workout = try XCTUnwrap(store.plan(for: userId)?.workouts.first { $0.kind == "push" })
        let outcome = try XCTUnwrap(SessionActions.quickComplete(from: workout, userId: userId, store: store))
        XCTAssertEqual(Array(outcome.awards.suffix(2)), [.achievement(id: "first-flame"), .achievement(id: "showed-up")]) // A21.9: the preview names them
        try SessionActions.post(outcome, shareToCrew: false, store: store) // A21.9: the tap earns them
        XCTAssertEqual(try store.gamificationState(for: userId).earnedAchievementIds, ["first-flame", "showed-up"])
        let again = try XCTUnwrap(SessionActions.quickComplete(from: workout, userId: userId, store: store))
        XCTAssertFalse(again.awards.contains(.achievement(id: "first-flame")))
    }
}
