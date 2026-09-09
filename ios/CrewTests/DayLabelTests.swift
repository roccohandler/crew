// SPEC: A6 (owner-directed 2026-09-08) — Today · Yesterday · Mon · Mon Sep 8 · Mon Sep 8, 2025; This week · Last week ·
// Week of Sep 1. Twin of web/tests/engine/day-label.test.ts: identical cases, identical labels.
// Runs on the open-source toolchain (ios/Package.swift) and under Xcode.

import XCTest
@testable import Crew

final class DayLabelTests: XCTestCase {
    private let today = "2026-09-08" // a Tuesday

    func testTodayYesterdayThenAWeekdayNameWithinTheWindow() {
        XCTAssertEqual(DayLabel.dayLabel("2026-09-08", todayKey: today), "Today")
        XCTAssertEqual(DayLabel.dayLabel("2026-09-07", todayKey: today), "Yesterday")
        XCTAssertEqual(DayLabel.dayLabel("2026-09-06", todayKey: today), "Sun")
        XCTAssertEqual(DayLabel.dayLabel("2026-09-03", todayKey: today), "Thu")
        XCTAssertEqual(DayLabel.dayLabel("2026-09-02", todayKey: today), "Wed") // six days back — the last weekday-only label
        XCTAssertEqual(DayLabel.dayLabel(DayKey.addDays(today, -SpecConstants.dayLabelWeekdayWithinDays), todayKey: today).count, "Wed".count)
    }

    func testADateInTheSameYearAndADateWithItsYearOtherwise() {
        XCTAssertEqual(DayLabel.dayLabel("2026-09-01", todayKey: today), "Tue Sep 1") // seven days back
        XCTAssertEqual(DayLabel.dayLabel(DayKey.addDays(today, -(SpecConstants.dayLabelWeekdayWithinDays + 1)), todayKey: today), "Tue Sep 1")
        XCTAssertEqual(DayLabel.dayLabel("2026-01-01", todayKey: today), "Thu Jan 1")
        XCTAssertEqual(DayLabel.dayLabel("2025-12-31", todayKey: today), "Wed Dec 31, 2025")
        XCTAssertEqual(DayLabel.dayLabel("2025-09-08", todayKey: today), "Mon Sep 8, 2025")
    }

    func testAFutureDayReadsAsADate() {
        XCTAssertEqual(DayLabel.dayLabel("2026-09-09", todayKey: today), "Wed Sep 9")
        XCTAssertEqual(DayLabel.dayLabel("2026-09-14", todayKey: today), "Mon Sep 14")
        XCTAssertEqual(DayLabel.dayLabel("2027-01-04", todayKey: today), "Mon Jan 4, 2027")
    }

    func testWeekHeaders() {
        XCTAssertEqual(DayLabel.weekHeader("2026-09-07", todayWeekKey: "2026-09-07"), "This week")
        XCTAssertEqual(DayLabel.weekHeader("2026-08-31", todayWeekKey: "2026-09-07"), "Last week")
        XCTAssertEqual(DayLabel.weekHeader("2026-08-24", todayWeekKey: "2026-09-07"), "Week of Aug 24")
        XCTAssertEqual(DayLabel.weekHeader("2025-12-29", todayWeekKey: "2026-09-07"), "Week of Dec 29")
    }
}
