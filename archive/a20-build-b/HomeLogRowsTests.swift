// SPEC: A20.1 / A20.2 / A20.3 / A20.5 / A20.11 (owner-directed 2026-09-11) — THE THREE ROW GRAMMARS OF TODAY'S LOG.
//
// These strings replace the workout card, the "Quick complete" secondary and the "Resume workout" banner — one intent
// that used to be reachable from three controls at three weights, which is what the owner read as "things don't look
// like they're syncing". The rows are the whole of A20's structural change, so they get their own file rather than
// pushing HomeModelTests past the C9 cap.
//
// A8 RUNS THROUGH EVERY BRANCH and is the thing most worth guarding: no row may print a zero as a verdict. The mockup
// that prompted this pass shows "15/15 sets" with no pre-session grammar, and the honest value there is "0/15" — the
// same defect that got "0/3" removed from the bridge (W043), from every Monday (A18.2) and from the paused header
// (A18.6b). Three removals of one rule is why it is asserted here directly.
//
// Against an in-memory Store, no mocks (C4). Not in ios/Package.swift: it reaches SwiftData through Store, which the
// Linux engine target does not build. Runs under Xcode with HomeModelTests. WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class HomeLogRowsTests: XCTestCase {
    private let userId = "home-user"
    private let tz = HomeTestFixtures.timeZone
    private let friday = HomeTestFixtures.friday // a training day in the Mon/Wed/Fri fixture plan
    private var saturday: Date { friday.addingTimeInterval(TimeInterval(TimeUnits.secondsPerDay)) }

    private func modelOnATrainingDay() throws -> (Store, HomeModel) {
        let store = try HomeTestFixtures.storeWithPlan(userId: userId)
        try HomeTestFixtures.post(store, userId: userId, id: "p1", dayKey: "2026-09-03") // clears the bridge (§1D) without counting today
        let model = HomeModel(store: store, userId: userId, timeZone: tz)
        model.refresh(now: friday)
        return (store, model)
    }

    func testTheThreeRowsSayWhatTodayHoldsAndNeverPrintAZero() throws {
        let (_, model) = try modelOnATrainingDay()
        let rows = model.logRows

        XCTAssertEqual(rows.map(\.id), ["workout", "cardio", "meal"], "A17.3 — the order never changes between states")
        XCTAssertEqual(rows.map(\.verb), ["Log workout", "Log cardio", "Log a meal"], "A20.2 — the title stays the VERB (6.6)")
        XCTAssertTrue(rows.allSatisfy { !$0.done }, "nothing is logged yet")

        // The plan fact, not a fraction: "0 of 15 sets" is the zero-as-verdict A8 bans
        XCTAssertTrue(rows[0].detail.hasPrefix("Push day · "), "got \(rows[0].detail)")
        XCTAssertFalse(rows[0].detail.contains("0 of"), "A8 — an unstarted workout must never report a zero")
        XCTAssertEqual(rows[1].detail, "Not logged today")
        XCTAssertEqual(rows[2].detail, "Nothing logged today")

        XCTAssertTrue(rows[0].offersQuickComplete, "A20.3 — the ONE named exception, and only on the workout row")
        XCTAssertFalse(rows[1].offersQuickComplete)
        XCTAssertFalse(rows[2].offersQuickComplete)
    }

    // SPEC: A20.5 — THE OPEN SESSION IS REPORTED ON THE ROW, NOT BESIDE IT. A "Resume workout · Push day" banner used
    // to appear at the top of the screen while the card below rendered "Resume workout": one verb, two weights, one
    // destination, and iOS rendered both at once while the web twin suppressed the banner — so the two engines had
    // silently disagreed about that state since before A18.8 existed. The row carries the PROGRESS, which is the fact
    // neither control had.
    func testAnOpenSessionBecomesTheRowsProgressAndTakesTheQuickCompleteAway() throws {
        let (store, model) = try modelOnATrainingDay()
        let workout = try XCTUnwrap(store.plan(for: userId)?.workouts.first)
        _ = try SessionActions.startSession(from: workout, kind: workout.kind, isPlannedDay: true, userId: userId, timeZone: tz, now: friday, store: store)
        model.refresh(now: friday)

        let row = model.logRows[0]
        XCTAssertTrue(row.detail.contains(" of "), "the row reports how far in the session is — got \(row.detail)")
        XCTAssertTrue(row.detail.contains("sets"), "got \(row.detail)")
        XCTAssertFalse(row.offersQuickComplete, "S07 — Quick Complete is gone once a session is open")
    }

    // SPEC: A20.1 — a REST day still offers all three vectors, and says so rather than going silent. A3 keeps the bonus
    // workout reachable and this is the sentence that names it; before A20 the only word for it was inside a sheet.
    func testARestDayNamesTheBonusAndOffersNoQuickComplete() throws {
        let store = try HomeTestFixtures.storeWithPlan(userId: userId)
        try HomeTestFixtures.post(store, userId: userId, id: "p2", dayKey: "2026-09-04")
        let model = HomeModel(store: store, userId: userId, timeZone: tz)
        model.refresh(now: saturday)

        XCTAssertEqual(model.today, .rest(posted: false))
        let rows = model.logRows
        XCTAssertEqual(rows.count, 3, "A17.3 — all three vectors on every state, in one order")
        XCTAssertEqual(rows[0].detail, "Nothing planned — bonus anytime")
        XCTAssertFalse(rows[0].offersQuickComplete, "there is no planned workout to quick-complete")
    }

    // SPEC: A20.11 — THE MEAL ROW COUNTS AND NOTHING ELSE. The mockup prints "2 meals · 1,240 kcal"; no calorie field
    // exists on either engine, A16 clause ⑥ says the plate journal carries "never a gram or a calorie", and the whole
    // nutrition-target surface is 18+ gated behind the owner's still-open ⏳ W070. This is the guard that keeps a
    // number off this line when Stage 9 eventually lands.
    func testTheMealRowCountsMealsAndCarriesNoNumberBeyondTheCount() throws {
        let (store, model) = try modelOnATrainingDay()
        try HomeTestFixtures.post(store, userId: userId, id: "m1", dayKey: "2026-09-04")
        model.refresh(now: friday)

        let meal = model.logRows[2]
        XCTAssertEqual(meal.detail, "1 meal")
        XCTAssertTrue(meal.done)
        XCTAssertFalse(meal.detail.lowercased().contains("kcal"), "A16 / A20.11 — no calorie may reach this line")
        XCTAssertFalse(meal.detail.contains("cal"), "A16 / A20.11 — no calorie may reach this line")
    }

    // SPEC: A20.7 — the date line, the one place the app states which day it is reasoning about.
    func testTheDateLineNamesTheDayInFull() throws {
        let (_, model) = try modelOnATrainingDay()
        XCTAssertEqual(model.dateLine, "Friday, Sep 4")
    }
}
