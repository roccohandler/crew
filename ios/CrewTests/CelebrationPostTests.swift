// SPEC: A21.9 / W4 (owner-approved 2026-09-17) — "no post exists until a celebration button is tapped": complete() leaves no
// LocalPost, nothing counted, and a patchSession op without `post`; post(_:shareToCrew:) inserts exactly one post with the tapped
// visibility, counts the day (S10: the numbers the celebration previewed) and queues the post; a second answer changes nothing;
// postUnanswered() answers a remembered celebration PRIVATELY at the next cold start. In-memory Store (C4). WRITTEN — UNVERIFIED.

import XCTest
@testable import Crew

@MainActor
final class CelebrationPostTests: XCTestCase {
    private let userId = "celebration-user"
    private let friday = ISO8601DateFormatter().date(from: "2026-09-04T18:00:00-07:00")!

    private func completedOutcome(in store: Store) throws -> CelebrationOutcome {
        let plan = PlanGenerator.generatePlan(days: [5], experience: "brandNew", seed: .shared)
        try PlanLocal.replace(plan, userId: userId, updatedAt: friday, store: store)
        let workout = try XCTUnwrap(store.plan(for: userId)?.workouts.first { $0.kind == "push" })
        return try XCTUnwrap(SessionActions.quickComplete(from: workout, userId: userId, now: friday, store: store))
    }

    override func setUp() {
        SessionActions.forgetUnanswered()
    }

    func testNoPostBeforeTheTapAndExactlyOneAfterIt() throws {
        let store = Store(inMemory: true)
        let outcome = try completedOutcome(in: store)
        XCTAssertNil(try store.post(forSessionClientId: outcome.postDraft.sessionClientId), "A21.9: no post before a button is tapped")
        XCTAssertTrue(try store.allPosts(for: userId).isEmpty)
        XCTAssertEqual(try store.gamificationState(for: userId).totalXP, 0, "nothing is counted until the tap")
        XCTAssertTrue(outcome.awards.contains(.xp(SpecConstants.xpPlannedWorkout, reason: .plannedWorkout)), "the preview names what the tap will count")

        let awards = try SessionActions.post(outcome, shareToCrew: true, now: friday, store: store)
        let post = try XCTUnwrap(store.post(forSessionClientId: outcome.postDraft.sessionClientId))
        XCTAssertTrue(post.shareToCrew)
        XCTAssertEqual(post.clientId, outcome.postDraft.clientId)
        XCTAssertEqual(post.type, "workout")
        XCTAssertEqual(awards, outcome.awards.filter { if case .prBadge = $0 { return false } else { return true } }, "the tap earns exactly what the celebration previewed")
        XCTAssertEqual(try store.gamificationState(for: userId).totalXP, SpecConstants.xpFirstPostOfDay + SpecConstants.xpPlannedWorkout)

        _ = try SessionActions.post(outcome, shareToCrew: false, now: friday, store: store) // a second answer changes nothing
        XCTAssertEqual(try store.allPosts(for: userId).count, 1)
        XCTAssertTrue(try XCTUnwrap(store.post(forSessionClientId: outcome.postDraft.sessionClientId)).shareToCrew)
    }

    func testAnUnansweredCelebrationPostsPrivatelyAtTheNextColdStart() throws {
        let store = Store(inMemory: true)
        let outcome = try completedOutcome(in: store)
        // the app dies here: no button tapped, the draft remembered outside the Store
        try SessionActions.postUnanswered(userId: userId, now: friday, store: store)
        let post = try XCTUnwrap(store.post(forSessionClientId: outcome.postDraft.sessionClientId))
        XCTAssertFalse(post.shareToCrew, "a private post is the quiet default (S10)")
        XCTAssertEqual(post.clientId, outcome.postDraft.clientId)
        try SessionActions.postUnanswered(userId: userId, now: friday, store: store) // nothing remembered any more
        XCTAssertEqual(try store.allPosts(for: userId).count, 1)
    }
}
