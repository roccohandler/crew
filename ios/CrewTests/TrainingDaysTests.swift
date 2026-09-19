// SPEC: A27 (a) as ruled 2026-09-18 — a day is judged by the training days in effect on that day; a change takes effect from the
// dayKey it is saved, forward, never backward; the history is append-only. Twin of web/tests/engine/training-days.test.ts:
// identical cases. The rules on the game engine are the vectors' (V85–V90); these pin the helpers every reader shares.

import XCTest
@testable import Crew

final class TrainingDaysTests: XCTestCase {
    private let history = [TrainingDaysEntry(from: "2026-09-01", weekdays: [1, 3, 5]), TrainingDaysEntry(from: "2026-09-16", weekdays: [2, 4, 6])]

    func testTheDayBeforeAChangeKeepsTheOldDaysAndTheChangeDayReadsTheNewOnes() {
        XCTAssertEqual(TrainingDays.weekdaysOn(history, "2026-09-15"), [1, 3, 5])
        XCTAssertEqual(TrainingDays.weekdaysOn(history, "2026-09-16"), [2, 4, 6])
        XCTAssertEqual(TrainingDays.weekdaysOn(history, "2026-10-30"), [2, 4, 6])
        XCTAssertTrue(TrainingDays.isPlannedOn(history, "2026-09-14"))   // Monday, old days
        XCTAssertFalse(TrainingDays.isPlannedOn(history, "2026-09-15"))  // Tuesday, still the old days
        XCTAssertFalse(TrainingDays.isPlannedOn(history, "2026-09-16"))  // Wednesday, the change day: the new days
        XCTAssertTrue(TrainingDays.isPlannedOn(history, "2026-09-17"))   // Thursday, new days
    }

    func testADayBeforeEveryEntryTakesTheFirstAndNoHistoryPlansNothing() {
        XCTAssertEqual(TrainingDays.weekdaysOn(history, "2026-08-03"), [1, 3, 5])
        XCTAssertTrue(TrainingDays.isPlannedOn(history, "2026-08-03"))
        XCTAssertEqual(TrainingDays.weekdaysOn([], "2026-09-14"), [])
        XCTAssertFalse(TrainingDays.isPlannedOn([], "2026-09-14"))
    }

    func testTwoChangesSavedTheSameDayTheLaterOneIsInEffect() {
        let sameDay = history + [TrainingDaysEntry(from: "2026-09-16", weekdays: [7])]
        XCTAssertEqual(TrainingDays.weekdaysOn(sameDay, "2026-09-16"), [7])
        XCTAssertEqual(TrainingDays.weekdaysOn(sameDay, "2026-09-15"), [1, 3, 5])
    }

    func testAppendAddsTheNewDaysFromTheDayTheyAreSavedAndNeverEditsAnEntry() {
        let next = TrainingDays.appendTrainingDays(history, weekdays: [6, 2, 4, 2, 7], savedDayKey: "2026-09-20")
        XCTAssertEqual(next, history + [TrainingDaysEntry(from: "2026-09-20", weekdays: [2, 4, 6, 7])])
        XCTAssertEqual(Array(next.prefix(history.count)), history)
    }

    func testTheSameDaysAgainAppendNothing() {
        XCTAssertEqual(TrainingDays.appendTrainingDays(history, weekdays: [6, 4, 2], savedDayKey: "2026-09-20"), history)
    }

    func testAnEditSavedBeforeTheLastEntrysDayTakesEffectFromThatDayNeverBehindIt() {
        XCTAssertEqual(TrainingDays.appendTrainingDays(history, weekdays: [1], savedDayKey: "2026-09-10"), history + [TrainingDaysEntry(from: "2026-09-16", weekdays: [1])])
    }

    func testTheFirstEntryOfANewPlanIsInEffectFromTheDayItIsSaved() {
        XCTAssertEqual(TrainingDays.appendTrainingDays([], weekdays: [3, 1, 5], savedDayKey: "2026-09-18"), [TrainingDaysEntry(from: "2026-09-18", weekdays: [1, 3, 5])])
    }
}
