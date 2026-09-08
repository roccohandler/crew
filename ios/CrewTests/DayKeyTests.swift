// SPEC: 8.3 "DayKey: 3 AM boundary, Monday weeks, DST, timezone shifts" — the unit half of T016 (the vector half is V05–V10 in
// VectorRunnerTests). Twin of web/tests/engine/day-key.test.ts: identical cases, identical expected keys. E8 · E20.
// Runs on the open-source toolchain (ios/Package.swift) and under Xcode. WRITTEN — UNVERIFIED on a Mac; verified on Linux.

import XCTest
@testable import Crew

final class DayKeyTests: XCTestCase {
    private let la = TimeZone(identifier: "America/Los_Angeles")!
    private let berlin = TimeZone(identifier: "Europe/Berlin")!
    private let auckland = TimeZone(identifier: "Pacific/Auckland")!
    private let utc = TimeZone(identifier: "UTC")!

    private func instant(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: iso)!
    }

    func testTwoFiftyNineIsYesterdayAndThreeIsToday() {
        XCTAssertEqual(DayKey.dayKey(for: instant("2026-09-08T09:59:00Z"), tz: la), "2026-09-07") // 02:59 PDT
        XCTAssertEqual(DayKey.dayKey(for: instant("2026-09-08T10:00:00Z"), tz: la), "2026-09-08") // 03:00 PDT
        XCTAssertEqual(DayKey.dayKey(for: instant("2026-09-08T00:59:00Z"), tz: berlin), "2026-09-07") // 02:59 CEST
        XCTAssertEqual(DayKey.dayKey(for: instant("2026-09-08T01:00:00Z"), tz: berlin), "2026-09-08") // 03:00 CEST
    }

    func testTheBoundaryHourIsTheSpecConstant() {
        let boundary = SpecConstants.dayBoundaryHour // UTC has no offset: the boundary is that hour on the clock
        var before = DateComponents(); before.year = 2026; before.month = 9; before.day = 8; before.hour = boundary - 1; before.minute = 59
        var at = DateComponents(); at.year = 2026; at.month = 9; at.day = 8; at.hour = boundary
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = utc
        XCTAssertEqual(DayKey.dayKey(for: calendar.date(from: before)!, tz: utc), "2026-09-07")
        XCTAssertEqual(DayKey.dayKey(for: calendar.date(from: at)!, tz: utc), "2026-09-08")
    }

    func testSpringForwardKeepsAFullDay() {
        // Los Angeles springs forward 2026-03-08 at 02:00 PST → 03:00 PDT: midnight is 08:00Z, +3 h absolute = 11:00Z = 04:00 PDT (V08)
        XCTAssertEqual(DayKey.dayKey(for: instant("2026-03-08T10:59:00Z"), tz: la), "2026-03-07")
        XCTAssertEqual(DayKey.dayKey(for: instant("2026-03-08T11:00:00Z"), tz: la), "2026-03-08")
    }

    func testFallBackBoundaryIsThreeAbsoluteHoursPastMidnight() {
        // Los Angeles falls back 2026-11-01 at 02:00 PDT → 01:00 PST: midnight is 07:00Z, +3 h = 10:00Z = 02:00 PST
        XCTAssertEqual(DayKey.dayKey(for: instant("2026-11-01T09:59:00Z"), tz: la), "2026-10-31")
        XCTAssertEqual(DayKey.dayKey(for: instant("2026-11-01T10:00:00Z"), tz: la), "2026-11-01")
    }

    func testTheSameInstantIsDifferentDaysAcrossTheDateLine() {
        let moment = instant("2026-09-08T15:30:00Z")
        XCTAssertEqual(DayKey.dayKey(for: moment, tz: la), "2026-09-08") // 08:30 PDT
        XCTAssertEqual(DayKey.dayKey(for: moment, tz: auckland), "2026-09-09") // 03:30 NZST — the 9th has begun
        XCTAssertEqual(DayKey.dayKey(for: instant("2026-09-08T14:30:00Z"), tz: auckland), "2026-09-08") // 02:30 NZST — still the 8th
    }

    func testWeekKeyIsTheMondayEvenForSunday() {
        for day in ["2026-09-07", "2026-09-08", "2026-09-10", "2026-09-12", "2026-09-13"] {
            XCTAssertEqual(DayKey.weekKey(for: day), "2026-09-07")
        }
        XCTAssertEqual(DayKey.weekKey(for: "2026-09-14"), "2026-09-14")
        XCTAssertEqual(DayKey.weekKey(for: "2026-09-06"), "2026-08-31")
        XCTAssertEqual(DayKey.isoWeekday("2026-09-07"), SpecConstants.weekStartWeekday)
        XCTAssertEqual(DayKey.isoWeekday("2026-09-13"), TimeUnits.daysPerWeek)
    }

    func testCalendarArithmeticCrossesYearEndsAndDSTChanges() {
        XCTAssertEqual(DayKey.addDays("2026-12-31", 1), "2027-01-01")
        XCTAssertEqual(DayKey.addDays("2026-03-01", -1), "2026-02-28")
        XCTAssertEqual(DayKey.daysBetween("2026-12-31", "2027-01-01"), 1)
        XCTAssertEqual(DayKey.daysBetween("2027-01-01", "2026-12-31"), -1)
        XCTAssertEqual(DayKey.daysBetween("2026-03-07", "2026-03-09"), 1 + 1)
        XCTAssertEqual(DayKey.daysBetween("2026-10-31", "2026-11-02"), 1 + 1)
    }
}
