// SPEC: A27 (a) as ruled 2026-09-18 (owner-approved) — the phone's half of the training-days history: PlanLocal appends a change of
// days (never an exercise edit) in effect from the day it is saved, the server's history replaces the rows, and the local readers —
// Home's week marks and the elapsed-day judge — ask the training days in effect ON each day. This file is NOT in ios/Package.swift:
// it reaches SwiftData through Store. WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class TrainingDaysLocalTests: XCTestCase {
    private let userId = "history-user"
    private let utc = TimeZone(identifier: "UTC")!
    // Mon/Wed/Fri until Thursday 2026-09-10, Tue/Thu/Sat from it
    private let history = [TrainingDaysEntry(from: "2026-09-01", weekdays: [1, 3, 5]), TrainingDaysEntry(from: "2026-09-10", weekdays: [2, 4, 6])]

    private func noon(_ dayKey: String) -> Date { ISO8601DateFormatter().date(from: "\(dayKey)T12:00:00Z")! }

    private func draft(_ days: [Int], kinds: [String] = ["push", "pull"]) -> PlanDraft {
        PlanDraft(trainingWeekdays: days, workouts: kinds.map { PlanDraftWorkout(name: "\($0) day", kind: $0, exercises: []) })
    }

    func testAChangeOfDaysOnThePhoneAppendsARowAndAnExerciseEditDoesNot() throws {
        let store = Store(inMemory: true)
        try PlanLocal.replace(draft([1, 3, 5]), userId: userId, updatedAt: noon("2026-09-01"), history: [history[0]], store: store)
        try PlanLocal.replace(draft([1, 3, 5], kinds: ["pull", "push"]), userId: userId, updatedAt: noon("2026-09-08"), timeZone: utc, store: store) // the rotation reordered
        XCTAssertEqual(try PlanLocal.trainingDays(for: userId, store: store), [history[0]])
        try PlanLocal.replace(draft([2, 4, 6]), userId: userId, updatedAt: noon("2026-09-10"), timeZone: utc, store: store)
        XCTAssertEqual(try PlanLocal.trainingDays(for: userId, store: store), history)
    }

    func testAnInstallFromBeforeA27GainsItsOwnDaysAsTheFirstRowWhenTheDaysChange() throws {
        let store = Store(inMemory: true)
        store.context.insert(LocalPlan(userId: userId, trainingWeekdays: [1, 3, 5], updatedAt: noon("2026-09-03"), workouts: []))
        try store.save()
        XCTAssertEqual(try PlanLocal.trainingDays(for: userId, store: store).map(\.weekdays), [[1, 3, 5]]) // no rows yet: its one plan's days
        try PlanLocal.replace(draft([2, 4, 6]), userId: userId, updatedAt: noon("2026-09-10"), timeZone: utc, store: store)
        let rows = try PlanLocal.trainingDays(for: userId, store: store)
        XCTAssertEqual(rows.map(\.weekdays), [[1, 3, 5], [2, 4, 6]])
        XCTAssertEqual(rows.last?.from, "2026-09-10")
        XCTAssertEqual(TrainingDays.weekdaysOn(rows, "2026-09-09"), [1, 3, 5]) // the day before the change keeps the old days
    }

    func testTheServersHistoryReplacesTheRows() throws {
        let store = Store(inMemory: true)
        try PlanLocal.replace(draft([1, 3, 5]), userId: userId, updatedAt: noon("2026-09-05"), timeZone: utc, store: store)
        try PlanLocal.replace(draft([2, 4, 6]), userId: userId, updatedAt: noon("2026-09-10"), history: history, store: store)
        XCTAssertEqual(try PlanLocal.trainingDays(for: userId, store: store), history)
    }

    func testTheWeekMarksJudgeTheDaysBeforeAChangeByTheOldDays() throws {
        let store = Store(inMemory: true)
        try PlanLocal.replace(draft([2, 4, 6]), userId: userId, updatedAt: noon("2026-09-10"), history: history, store: store)
        let marks = try HomeModel.weekMarks(userId: userId, plan: try store.plan(for: userId), todayKey: "2026-09-10", pause: nil, store: store)
        XCTAssertEqual(marks.days, [.missed, .rest, .missed, .today, .rest, .nextUp, .rest]) // Mon, Wed by the old days; Thu, Sat by the new
        XCTAssertEqual(marks.planned, 4)
    }

    func testElapsedDaysAreJudgedByTheDaysInEffectOnEach() throws {
        let store = Store(inMemory: true)
        try PlanLocal.replace(draft([2, 4, 6]), userId: userId, updatedAt: noon("2026-09-10"), history: history, store: store)
        var state = GamificationState()
        state.currentStreak = 3
        state.longestStreak = 3
        state.shields = 2
        state.lastCountedDayKey = "2026-09-05"
        state.judgedThroughDayKey = "2026-09-06"
        try GamificationLocal.persist(state, for: userId, store: store)
        _ = try GamificationLocal.judgeElapsedDays(for: userId, store: store, now: noon("2026-09-12"), timeZone: utc)
        let after = try GamificationLocal.engineState(for: userId, store: store)
        // Monday and Wednesday (old days) take the two shields; Thursday (new days) breaks the streak; Tuesday and Friday ask nothing.
        // Judged by today's days alone, Tuesday and Thursday would have taken the shields and the streak would stand at 3.
        XCTAssertEqual(after.shields, 0)
        XCTAssertEqual(after.currentStreak, 0)
        XCTAssertEqual(after.judgedThroughDayKey, "2026-09-11")
    }
}
