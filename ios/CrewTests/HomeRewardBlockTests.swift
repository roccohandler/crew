// SPEC: A28 (b) (owner-approved 2026-09-19) — orange is a point: on Home only the ring's stroke and the flame glyph, so the
// accent budget per state is two (a live streak and a week with a completed workout), one off-season (the ring stays, the flame
// becomes a slate snowflake) and zero where the reward block is absent (the first day, no plan — HomeScreen does not draw it).
// mvp-definition R1's "accent-budget assertion". R-084 (1): A18.2's gate — no ring until the week holds a completed workout.
// WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

final class HomeRewardBlockTests: XCTestCase {
    func testATrainingRestOrDoneDayWithALiveStreakAndAWorkoutThisWeekSpendsTwo() {
        XCTAssertEqual(HomeRewardBlock.accentMarks(streak: 6, ringDone: 2, ringPlanned: 4, isPaused: false), 2)
    }

    func testOffSeasonKeepsTheRingAndSpendsOne() {
        XCTAssertEqual(HomeRewardBlock.accentMarks(streak: 6, ringDone: 2, ringPlanned: 4, isPaused: true), 1)
        XCTAssertFalse(HomeRewardBlock.flameIsAccent(streak: 6, isPaused: true))
    }

    func testAWeekWithNothingDoneShowsNoRing() {
        XCTAssertFalse(HomeRewardBlock.showsRing(ringDone: 0, ringPlanned: 4))
        XCTAssertEqual(HomeRewardBlock.accentMarks(streak: 6, ringDone: 0, ringPlanned: 4, isPaused: false), 1)
    }

    func testAStreakOfZeroIsAnUnlitFlame() {
        XCTAssertFalse(HomeRewardBlock.flameIsAccent(streak: 0, isPaused: false))
        XCTAssertEqual(HomeRewardBlock.accentMarks(streak: 0, ringDone: 0, ringPlanned: 4, isPaused: false), 0)
    }

    func testNoPlanMeansNoRing() {
        XCTAssertFalse(HomeRewardBlock.showsRing(ringDone: 0, ringPlanned: 0))
    }
}
