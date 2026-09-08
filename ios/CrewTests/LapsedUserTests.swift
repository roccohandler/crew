// SPEC: T042 (Verify: unit) — the 14-day welcome-back trigger (E4/S18) and the stale-session rule (S01); the same cases as
// web tests/engine/lapsed-user.test.ts. WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

final class LapsedUserTests: XCTestCase {
    func testQuietDaysCountFromTheLastActivity() {
        XCTAssertEqual(LapsedUser.quietDays(lastActivityDay: "2026-09-01", today: "2026-09-15"), 14)
        XCTAssertEqual(LapsedUser.quietDays(lastActivityDay: "2026-09-15", today: "2026-09-01"), 0)
    }

    func testTriggersAtFourteenQuietDaysNotThirteen() {
        XCTAssertFalse(LapsedUser.shouldShowWelcomeBack(lastActivityDay: "2026-09-01", ackDay: nil, today: "2026-09-14"))
        XCTAssertTrue(LapsedUser.shouldShowWelcomeBack(lastActivityDay: "2026-09-01", ackDay: nil, today: "2026-09-15"))
        XCTAssertEqual(SpecConstants.lapsedUserQuietDays, 14)
    }

    func testNeverShowsWithoutAPost() {
        XCTAssertFalse(LapsedUser.shouldShowWelcomeBack(lastActivityDay: nil, ackDay: nil, today: "2026-09-15"))
    }

    func testStaysSilentOnceAcknowledgedThisQuietSpell() {
        XCTAssertFalse(LapsedUser.shouldShowWelcomeBack(lastActivityDay: "2026-09-01", ackDay: "2026-09-15", today: "2026-09-15"))
        XCTAssertFalse(LapsedUser.shouldShowWelcomeBack(lastActivityDay: "2026-09-01", ackDay: "2026-09-15", today: "2026-10-30"))
    }

    func testShowsAgainAfterActivityAndAFreshQuietSpell() {
        XCTAssertTrue(LapsedUser.shouldShowWelcomeBack(lastActivityDay: "2026-09-20", ackDay: "2026-09-15", today: "2026-10-04"))
    }

    func testStaleAfterMoreThanADayNotBefore() {
        let started = Date(timeIntervalSince1970: 1_788_000_000)
        let limit = TimeInterval(SpecConstants.staleInProgressSessionAfterHours * TimeUnits.secondsPerHour)
        XCTAssertFalse(LapsedUser.isStaleSession(startedAt: started, now: started.addingTimeInterval(limit)))
        XCTAssertTrue(LapsedUser.isStaleSession(startedAt: started, now: started.addingTimeInterval(limit + 1)))
    }
}
