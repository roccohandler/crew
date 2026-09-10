// SPEC: A17.1 — the sentence that answers "what is this screen for / what are the colours for". Twin of
// web/tests/engine/week-summary.test.ts: the same cases, the same expected strings, so the eye and VoiceOver on two
// platforms cannot print four different sentences from one week.

import XCTest
@testable import Crew

final class WeekSummaryTests: XCTestCase {
    // The owner's actual week when they reported the complaint: trains Mon/Wed/Sun, missed Monday, did Wednesday,
    // opened the app on Thursday, next workout Sunday — and the strip showed Sunday identically to Friday.
    func testNamesTheDoneDayTheMissedDayAndTheNextOne() {
        let states = ["missed", "rest", "done", "today", "rest", "rest", "nextUp"]
        XCTAssertEqual(WeekSummary.weekSummary(states).short, "This week: Wed done · Mon missed · next Sun")
        XCTAssertEqual(WeekSummary.weekSummary(states).spoken, "This week: Wednesday done, Monday missed, today Thursday, next workout Sunday.")
    }

    // A8 — a week with nothing in it says so in words. Never "0 done", never an empty count.
    func testSaysNothingLoggedYetRatherThanAZero() {
        let states = ["rest", "today", "rest", "rest", "nextUp", "rest", "rest"]
        XCTAssertEqual(WeekSummary.weekSummary(states).short, "This week: nothing logged yet · next Fri")
        XCTAssertEqual(WeekSummary.weekSummary(states).spoken, "This week: nothing logged yet, today Tuesday, next workout Friday.")
    }

    func testListsSeveralDoneDaysInWeekOrder() {
        let states = ["done", "rest", "done", "rest", "today", "rest", "upcoming"]
        XCTAssertEqual(WeekSummary.weekSummary(states).short, "This week: Mon, Wed done")
        XCTAssertEqual(WeekSummary.weekSummary(states).spoken, "This week: Monday, Wednesday done, today Friday.")
    }

    // A plan with no further training day this week omits the clause rather than inventing one
    func testOmitsTheNextClauseWhenThereIsNoNextTrainingDay() {
        let states = ["done", "rest", "missed", "rest", "today", "rest", "rest"]
        XCTAssertEqual(WeekSummary.weekSummary(states).short, "This week: Mon done · Wed missed")
        XCTAssertEqual(WeekSummary.weekSummary(states).spoken, "This week: Monday done, Wednesday missed, today Friday.")
    }

    // `upcoming` is a planned day that is NOT the next one — it is deliberately silent, so the sentence names one
    // future day, not three (A17.4: mark the next training day only)
    func testNeverNamesAnUpcomingDayThatIsNotTheNextOne() {
        let states = ["today", "nextUp", "upcoming", "rest", "upcoming", "rest", "rest"]
        XCTAssertEqual(WeekSummary.weekSummary(states).short, "This week: nothing logged yet · next Tue")
    }

    // The strip can be rendered before a plan exists; an empty week must not crash or print a dangling separator
    func testHandlesAnEmptyWeek() {
        XCTAssertEqual(WeekSummary.weekSummary([]).short, "This week: nothing logged yet")
        XCTAssertEqual(WeekSummary.weekSummary([]).spoken, "This week: nothing logged yet.")
    }
}
