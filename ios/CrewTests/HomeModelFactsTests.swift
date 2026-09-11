// SPEC: A18.3 (the what's-next fact in two shapes) · A18.6a (a paused week reports no misses) · A18.9 (the all-done
// card reports the day) — the facts HomeModel REPORTS, at the model level, against an in-memory Store with no mocks (C4).
//
// Split from HomeModelTests.swift for the C9 200-line cap, the way HomeModel+Facts.swift is split from HomeModel.swift
// and HomeModelEdgeTests.swift was split before it. The STATIC halves of the same rules are pinned one level down in
// HomeVectorSlotsTests. WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class HomeModelFactsTests: XCTestCase {
    private let userId = "home-facts-user"
    private let tz = HomeTestFixtures.timeZone
    private let friday = HomeTestFixtures.friday
    private var saturday: Date { friday.addingTimeInterval(TimeInterval(TimeUnits.secondsPerDay)) }

    private func storeWithPlan() throws -> Store { try HomeTestFixtures.storeWithPlan(userId: userId) }
    private func post(_ store: Store, id: String, dayKey: String) throws { try HomeTestFixtures.post(store, userId: userId, id: id, dayKey: dayKey) }

    // SPEC: A18.3 — the what's-next fact comes in TWO halves so the block above the card can title it, and the
    // one-sentence form the bridge renders is derived from the same halves rather than computed twice.
    func testWhatsNextIsOneComputationInTwoShapes() throws {
        let store = try storeWithPlan()
        try post(store, id: "p-nextup", dayKey: "2026-09-04")
        let model = HomeModel(store: store, userId: userId, timeZone: tz)
        model.refresh(now: saturday) // Saturday is a rest day in the Mon/Wed/Fri plan
        let facts = try XCTUnwrap(model.nextUp)
        XCTAssertEqual(facts.heading, "Next workout")
        XCTAssertEqual(facts.detail, "Mon · Push day")
        XCTAssertEqual(model.nextUpLine, "\(facts.heading): \(facts.detail)")
    }

    // SPEC: A18.3 — an undone TRAINING day carries no block: the card already is what is next, and that state is the
    // tallest on the smallest phone. A PAUSED day carries none either, deliberately — the next training day would be
    // inside the pause window, so the block would promise a workout on a day the app has already frozen.
    func testNoWhatsNextBlockOnATrainingDayOrWhilePaused() throws {
        let store = try storeWithPlan()
        try post(store, id: "p-training", dayKey: "2026-09-03")
        let model = HomeModel(store: store, userId: userId, timeZone: tz)
        model.refresh(now: friday)
        XCTAssertNil(model.nextUp)

        store.context.insert(LocalPause(userId: userId, startDay: "2026-09-03", endDay: "2026-09-12", createdAt: friday))
        try store.save()
        let paused = HomeModel(store: store, userId: userId, timeZone: tz)
        paused.refresh(now: friday)
        XCTAssertEqual(paused.today, .paused(until: "Sat Sep 12"))
        XCTAssertNil(paused.nextUp)
    }

    // SPEC: A18.9 — the all-done card reports the day, and the model is where that fact is computed (5.6.6).
    func testTodaySummaryLinesReportTheDaysCompletedWork() throws {
        let store = try storeWithPlan()
        try post(store, id: "p-done", dayKey: "2026-09-04")
        let model = HomeModel(store: store, userId: userId, timeZone: tz)
        model.refresh(now: friday)
        XCTAssertEqual(model.todaySummaryLines, [], "nothing completed yet, so nothing to report")

        let workout = try XCTUnwrap(store.plan(for: userId)?.workouts.first)
        _ = try SessionActions.quickComplete(from: workout, userId: userId, shareToCrew: false, now: friday, store: store)
        model.refresh(now: friday)
        XCTAssertEqual(model.today, .allDone)
        XCTAssertEqual(model.todaySummaryLines.count, 1)
        XCTAssertTrue(model.todaySummaryLines[0].hasPrefix("Push day · "), "the journal's own line, not a second one: \(model.todaySummaryLines)")
    }

    // SPEC: A18.6a — Flow 7 and spec:460 promise "pauses without penalty". A17.1 turned the strip's grey dots into the
    // English sentence "This week: Mon missed", printed directly above a card saying the streak is frozen, so a
    // pause-blind mark is now a contradiction a reader can see rather than a dot nobody decodes.
    func testAPausedWeekReportsNoMissesAndNoRing() throws {
        let store = try storeWithPlan()
        try post(store, id: "p-frozen", dayKey: "2026-09-01")
        store.context.insert(LocalPause(userId: userId, startDay: "2026-08-31", endDay: "2026-09-12", createdAt: friday))
        try store.save()
        let model = HomeModel(store: store, userId: userId, timeZone: tz)
        model.refresh(now: friday)
        XCTAssertFalse(model.weeklyRing.contains(.missed))
        XCTAssertEqual(model.ringPlanned, 0)
    }
}
