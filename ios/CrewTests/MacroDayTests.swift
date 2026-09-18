// SPEC: nutrition addendum §4 · clause ② · §7.4 encoder ⑤ — the words, the bar and the template ticks on Today. Twin of
// web/tests/engine/macro-day.test.ts: the same cases, the same expected values, so two platforms cannot print two different lines
// from one day. (V61–V63 pin remaining / logging / gameEvents; these pin what the screen derives from them.)

import XCTest
@testable import Crew

final class MacroDayTests: XCTestCase {
    func testPrintsTheAmountsThenToGo() {
        let line = MacroDay.macroLine(95, 145)
        XCTAssertEqual(MacroDay.amountText(line, unit: "g"), "95 / 145 g")
        XCTAssertEqual(MacroDay.restText(line), "50 to go")
    }

    func testPrintsOverAsASecondFactNeverBoth() {
        let line = MacroDay.macroLine(2700, 2660)
        XCTAssertEqual(MacroDay.amountText(line, unit: "kcal"), "2700 / 2660 kcal")
        XCTAssertEqual(MacroDay.restText(line), "40 over")
    }

    func testSpeaksALineAsOneSentence() {
        XCTAssertEqual(MacroDay.spokenLine("Protein", MacroDay.macroLine(95, 145), unit: "g"), "Protein: 95 / 145 g, 50 to go")
        XCTAssertEqual(MacroDay.spokenLine("Calories", MacroDay.macroLine(2660, 2660), unit: "kcal"), "Calories: 2660 / 2660 kcal")
    }

    // A8 — exactly on target prints no "0 to go": the amounts already say it, and a zero is never a verdict
    func testSaysNothingMoreWhenTheTargetIsMetExactly() {
        XCTAssertNil(MacroDay.restText(MacroDay.macroLine(145, 145)))
    }

    // Clause ② — an overage names tomorrow in the same breath; a day on or under target says nothing at all
    func testTheHorizonLineIsSilentUntilAnyLineIsOver() {
        let targets = MacroGrams(proteinG: 145, carbsG: 385, fatG: 60)
        XCTAssertNil(MacroDay.horizonText(MacroDay.remaining(targets, [])))
        XCTAssertNil(MacroDay.horizonText(MacroDay.remaining(targets, [MealLogFacts(clientId: "a", proteinG: 145, carbsG: 385, fatG: 60)])))
        XCTAssertEqual(MacroDay.horizonText(MacroDay.remaining(targets, [MealLogFacts(clientId: "a", proteinG: 0, carbsG: 0, fatG: 65)])), "Tomorrow starts from your full targets.")
    }

    func testPrintsAMealsThreeNumbersInTheFixedOrderAndSpeaksThemInWords() {
        let grams = MacroGrams(proteinG: 30, carbsG: 45, fatG: 10)
        XCTAssertEqual(MacroDay.gramsText(grams), "P 30 · C 45 · F 10")
        XCTAssertEqual(MacroDay.gramsSpoken(grams), "30 grams protein, 45 grams carbs, 10 grams fat")
    }

    func testTheBarFillsTowardTheHairlineAtEightyPercentOfTheTrack() {
        XCTAssertEqual(MacroDay.barPercent(MacroDay.macroLine(0, 145)), 0)
        XCTAssertEqual(MacroDay.barPercent(MacroDay.macroLine(145, 145)), 80)
        XCTAssertEqual(MacroDay.barPercent(MacroDay.macroLine(72, 145)), 39) // floor(72 × 80 / 145)
    }

    func testAnOverageShowsAsLengthAndStopsAtTheEndOfTheTrack() {
        XCTAssertEqual(MacroDay.barPercent(MacroDay.macroLine(160, 145)), 88)
        XCTAssertEqual(MacroDay.barPercent(MacroDay.macroLine(400, 145)), 100)
    }

    func testTheBarNeverDividesByAZeroTarget() {
        XCTAssertEqual(MacroDay.barPercent(MacroDay.macroLine(0, 0)), 0)
        XCTAssertEqual(MacroDay.barPercent(MacroDay.macroLine(10, 0)), 100)
    }

    func testTicksASlotWithTheLogOfItsMeal() {
        XCTAssertEqual(MacroDay.slotTicks(["oats", "shake"], logs: [SlotLog(clientId: "log-1", savedMealId: "shake")]), [nil, "log-1"])
    }

    func testTicksTheSameMealInTwoSlotsOneLogAtATimeInOrder() {
        let logs = [SlotLog(clientId: "log-1", savedMealId: "shake"), SlotLog(clientId: "log-2", savedMealId: "shake")]
        XCTAssertEqual(MacroDay.slotTicks(["shake", "oats", "shake"], logs: [logs[0]]), ["log-1", nil, nil])
        XCTAssertEqual(MacroDay.slotTicks(["shake", "oats", "shake"], logs: logs), ["log-1", nil, "log-2"])
    }

    func testIsNeverTickedByAQuickAddOrByAMealThatIsNotInTheTemplate() {
        let logs = [SlotLog(clientId: "log-1", savedMealId: nil), SlotLog(clientId: "log-2", savedMealId: "wrap")]
        XCTAssertEqual(MacroDay.slotTicks(["oats"], logs: logs), [nil])
    }
}
