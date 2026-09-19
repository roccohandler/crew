// SPEC: A28 (e) · GAP 10 as R-086 reads it — the season label's day arithmetic. Twin of web/tests/progress-season.test.ts: identical
// cases. WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

final class SeasonFactsTests: XCTestCase {
    private let built = [TrainingDaysEntry(from: "2026-08-10", weekdays: [1, 3, 5])] // a Monday

    func testCountsTheCalendarWeeksFromTheBuildToTodayAndTheWorkoutsInsideThem() throws {
        let facts = try XCTUnwrap(SeasonFacts.of(history: built, endedPauseDays: [], workoutDayKeys: ["2026-08-10", "2026-08-12", "2026-09-18", "2026-08-01"], todayKey: "2026-09-19"))
        XCTAssertEqual(facts, SeasonFacts(startDayKey: "2026-08-10", weeks: 6, workouts: 3))
        XCTAssertEqual(facts.line, "This season · 6 weeks · 3 workouts")
    }

    func testRestartsAtTheEndOfTheLatestPauseThatHasRunItsCourse() {
        XCTAssertEqual(SeasonFacts.of(history: built, endedPauseDays: ["2026-09-07", "2026-08-24"], workoutDayKeys: ["2026-09-01", "2026-09-08"], todayKey: "2026-09-19"), SeasonFacts(startDayKey: "2026-09-07", weeks: 2, workouts: 1))
        XCTAssertEqual(SeasonFacts.of(history: built, endedPauseDays: ["2026-09-25"], workoutDayKeys: [], todayKey: "2026-09-19")?.startDayKey, "2026-08-10")
    }

    func testADaysChangeIsNotARestart() {
        let changed = built + [TrainingDaysEntry(from: "2026-09-02", weekdays: [2, 4])]
        XCTAssertEqual(SeasonFacts.of(history: changed, endedPauseDays: [], workoutDayKeys: [], todayKey: "2026-09-19")?.startDayKey, "2026-08-10")
    }

    func testASeasonThatStartedThisWeekReadsInTheSingularAndNoHistoryReadsNothing() {
        XCTAssertEqual(SeasonFacts.of(history: [TrainingDaysEntry(from: "2026-09-17", weekdays: [4])], endedPauseDays: [], workoutDayKeys: ["2026-09-17"], todayKey: "2026-09-19")?.line, "This season · 1 week · 1 workout")
        XCTAssertNil(SeasonFacts.of(history: [], endedPauseDays: [], workoutDayKeys: [], todayKey: "2026-09-19"))
    }
}
