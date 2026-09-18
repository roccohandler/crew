// SPEC: nutrition addendum §2–§4 (RATIFIED 2026-09-18) · 5.6.3 (the six nutrition ops) · clauses ③ ④ · V62 · V64 — the phone's
// nutrition writes against an in-memory SwiftData container and a test-provided sender, no mocks (C4): every write changes the row
// FIRST and queues its op SECOND, in order; a log copies its meal; deleting a meal takes its slot and leaves the day alone; the pull
// waits while the phone is ahead; Home's row is a COUNT and is absent under 18; and a macro entry never touches the game state or
// creates a post. This file is NOT in ios/Package.swift (it reaches SwiftData through Store). WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class NutritionLocalTests: XCTestCase {
    private let userId = "nutrition-user"
    private let tz = TimeZone(identifier: "America/Los_Angeles")!
    private let friday = ISO8601DateFormatter().date(from: "2026-09-04T18:00:00-07:00")!
    private let dayKey = "2026-09-04"

    private func make() -> (Store, SyncQueue) {
        let store = Store(inMemory: true)
        return (store, SyncQueue(store: store, send: { op in SyncResponseDTO(results: [SyncOpResultDTO(opId: op.opId, ok: true, error: nil, retryable: nil)], gamification: nil) }))
    }

    // Each write gets its own second: the queue is FIFO by createdAt, and two ops stamped with one instant have no order
    private func at(_ seconds: Int) -> Date { friday.addingTimeInterval(TimeInterval(seconds)) }

    private func queuedKinds(_ store: Store) throws -> [String] {
        try store.pendingOps().map(\.kind)
    }

    // V57 / V58 on the phone: 176 lb derives 80 kg's lines, and the op carries NO grams (the server derives the same numbers)
    func testDerivedTargetsAreTheEngineTwinsAndTheOpCarriesNoGrams() throws {
        let (store, queue) = make()
        try NutritionActions.setTargets(bodyweightTenths: 1760, unit: "lb", manual: nil, userId: userId, now: at(0), store: store, queue: queue)
        let targets = try XCTUnwrap(NutritionLocal.targets(for: userId, store: store))
        XCTAssertEqual([targets.proteinG, targets.carbsG, targets.fatG], [145, 385, 60])
        XCTAssertEqual(targets.source, "derived")
        let payload = try JSONDecoder.crew.decode(PutTargetsPayload.self, from: try XCTUnwrap(store.pendingOps().first).payload)
        XCTAssertEqual(payload, PutTargetsPayload(bodyweight: 176, unit: "lb"))
        try NutritionActions.setTargets(bodyweightTenths: 1760, unit: "lb", manual: MacroGrams(proteinG: 160, carbsG: 350, fatG: 70), userId: userId, now: at(1), store: store, queue: queue)
        XCTAssertEqual(try XCTUnwrap(NutritionLocal.targets(for: userId, store: store)).source, "manual")
    }

    // 8.3 ordering — the meal goes up before the template and the log that name it; the log COPIES the meal (V62)
    func testALoggedSlotCopiesItsMealAndTheOpsQueueInOrder() throws {
        let (store, queue) = make()
        let mealId = try NutritionActions.saveMeal(clientId: nil, name: "Oats and whey", grams: MacroGrams(proteinG: 30, carbsG: 45, fatG: 10), seed: nil, userId: userId, now: at(0), store: store, queue: queue)
        try NutritionActions.putTemplate([TemplateSlotFacts(savedMealId: mealId, label: "Breakfast")], userId: userId, now: at(1), store: store, queue: queue)
        let meal = try XCTUnwrap(NutritionLocal.meal(clientId: mealId, store: store))
        let logId = try NutritionActions.logMeal(meal, userId: userId, timeZone: tz, now: at(2), store: store, queue: queue)
        XCTAssertEqual(try queuedKinds(store), ["upsertSavedMeal", "putDayTemplate", "createMealLog"])
        let log = try XCTUnwrap(NutritionLocal.log(clientId: logId, store: store))
        XCTAssertEqual([log.dayKey, log.name, log.savedMealId ?? ""], [dayKey, "Oats and whey", mealId])
        XCTAssertEqual([log.proteinG, log.carbsG, log.fatG], [30, 45, 10])
        meal.proteinG = 99 // editing the meal later never rewrites the day
        XCTAssertEqual(try XCTUnwrap(NutritionLocal.log(clientId: logId, store: store)).proteinG, 30)
    }

    // §4 — one tap logs, the same tap undoes; the model's lines follow
    func testTheSameTapUndoesALoggedSlot() throws {
        let (store, queue) = make()
        try NutritionActions.setTargets(bodyweightTenths: 800, unit: "kg", manual: nil, userId: userId, now: at(0), store: store, queue: queue)
        let mealId = try NutritionActions.saveMeal(clientId: nil, name: "Shake", grams: MacroGrams(proteinG: 25, carbsG: 5, fatG: 2), seed: nil, userId: userId, now: at(1), store: store, queue: queue)
        try NutritionActions.putTemplate([TemplateSlotFacts(savedMealId: mealId, label: ""), TemplateSlotFacts(savedMealId: mealId, label: "Evening")], userId: userId, now: at(2), store: store, queue: queue)
        let model = NutritionTodayModel(store: store, userId: userId, availability: .available, weightUnit: "kg", timeZone: tz, queue: queue)
        model.refresh(now: friday)
        XCTAssertEqual(model.slots.map(\.title), ["Shake", "Evening · Shake"])
        model.tapSlot(try XCTUnwrap(model.slots.first), now: at(3))
        XCTAssertEqual(model.slots.map { $0.tickedLogId != nil }, [true, false]) // the same meal in two slots ticks one at a time
        XCTAssertEqual(model.remaining?.protein, MacroLine(logged: 25, target: 145, toGo: 120, over: 0))
        model.tapSlot(try XCTUnwrap(model.slots.first), now: at(4))
        XCTAssertEqual(model.slots.map { $0.tickedLogId != nil }, [false, false])
        XCTAssertTrue(model.logs.isEmpty)
        XCTAssertEqual(try queuedKinds(store).suffix(2), ["createMealLog", "deleteMealLog"])
    }

    // §2 — "deleting the meal removes the slot"; the day already logged keeps its own copy
    func testDeletingAMealTakesItsSlotAndLeavesTheDayAlone() throws {
        let (store, queue) = make()
        let mealId = try NutritionActions.saveMeal(clientId: nil, name: "Wrap", grams: MacroGrams(proteinG: 20, carbsG: 30, fatG: 8), seed: nil, userId: userId, now: at(0), store: store, queue: queue)
        try NutritionActions.putTemplate([TemplateSlotFacts(savedMealId: mealId, label: "Lunch")], userId: userId, now: at(1), store: store, queue: queue)
        _ = try NutritionActions.logMeal(try XCTUnwrap(NutritionLocal.meal(clientId: mealId, store: store)), userId: userId, timeZone: tz, now: at(2), store: store, queue: queue)
        try NutritionActions.deleteMeal(clientId: mealId, userId: userId, now: at(3), store: store, queue: queue)
        XCTAssertTrue(try NutritionLocal.slots(for: userId, store: store).isEmpty)
        XCTAssertEqual(try NutritionLocal.logs(for: userId, dayKey: dayKey, store: store).map(\.name), ["Wrap"])
    }

    // The pull REPLACES the phone's rows with the server's and translates server ids to the clientIds the phone keys by — but never
    // while a nutrition op is still queued (the phone is ahead)
    func testThePullReplacesTheRowsAndWaitsWhileThePhoneIsAhead() throws {
        let (store, queue) = make()
        let meal = SavedMealDTO(id: "64f0c0ffee0000000000000a", clientId: "meal-client-id", name: "Oats", proteinG: 20, carbsG: 60, fatG: 10, source: SavedMealSourceDTO(kind: "manual", chainId: nil, itemId: nil), createdAt: friday)
        let targets = NutritionTargetsDTO(bodyweight: 80.5, unit: "kg", proteinG: 145, carbsG: 385, fatG: 60, source: "derived", updatedAt: friday)
        let log = MealLogDTO(id: "64f0c0ffee0000000000000b", clientId: "log-client-id", dayKey: dayKey, savedMealId: meal.id, name: "Oats", proteinG: 20, carbsG: 60, fatG: 10, quickAdd: false, createdAt: friday)
        try NutritionHydrate.write(targets: targets, meals: [meal], slots: [TemplateSlotDTO(savedMealId: meal.id, label: "Breakfast", meal: meal)], logs: [log], userId: userId, dayKey: dayKey, store: store, now: friday)
        XCTAssertEqual(try XCTUnwrap(NutritionLocal.targets(for: userId, store: store)).bodyweightTenths, 805)
        XCTAssertEqual(try NutritionLocal.slots(for: userId, store: store), [TemplateSlotFacts(savedMealId: "meal-client-id", label: "Breakfast")])
        XCTAssertEqual(try NutritionLocal.logs(for: userId, dayKey: dayKey, store: store).map(\.savedMealId), ["meal-client-id"])
        XCTAssertTrue(try NutritionLocal.queuedOps(store: store).isEmpty)
        _ = try NutritionActions.quickAdd(MacroGrams(proteinG: 40, carbsG: 0, fatG: 0), userId: userId, timeZone: tz, now: at(0), store: store, queue: queue)
        XCTAssertEqual(try NutritionLocal.queuedOps(store: store).map(\.kind), ["createMealLog"]) // NutritionHydrate.pull returns false on this
    }

    // A22 G4 · A16.c — Home's third row: absent under 18, an invitation with nothing logged (A8), a COUNT otherwise
    func testTheMacrosRowIsAbsentUnder18AndReportsACountOtherwise() throws {
        let (store, queue) = make()
        XCTAssertNil(try HomeModel.slots(userId: userId, dayKey: dayKey, nutrition: .absent, store: store).macros)
        XCTAssertEqual(try HomeModel.slots(userId: userId, dayKey: dayKey, nutrition: .askBirthYear, store: store).macros, MacrosSlot(logged: nil))
        _ = try NutritionActions.quickAdd(MacroGrams(proteinG: 40, carbsG: 0, fatG: 0), userId: userId, timeZone: tz, now: at(0), store: store, queue: queue)
        _ = try NutritionActions.quickAdd(MacroGrams(proteinG: 0, carbsG: 30, fatG: 0), userId: userId, timeZone: tz, now: at(1), store: store, queue: queue)
        XCTAssertEqual(try HomeModel.slots(userId: userId, dayKey: dayKey, nutrition: .available, store: store).macros, MacrosSlot(logged: 2))
    }

    // Clauses ③ ④ · V63 — a macro entry pays nothing and posts nothing: the game state and the journal are exactly as they were
    func testAMacroEntryNeverTouchesTheGameStateOrTheJournal() throws {
        let (store, queue) = make()
        let before = try store.gamificationState(for: userId)
        let snapshot = [before.totalXP, before.currentStreak, before.shields, before.level]
        _ = try NutritionActions.quickAdd(MacroGrams(proteinG: 40, carbsG: 50, fatG: 10), userId: userId, timeZone: tz, now: at(0), store: store, queue: queue)
        let after = try store.gamificationState(for: userId)
        XCTAssertEqual([after.totalXP, after.currentStreak, after.shields, after.level], snapshot)
        XCTAssertTrue(try store.allPosts(for: userId).isEmpty)
        XCTAssertTrue(after.earnedAchievementIds.isEmpty)
    }

    // §4 "Delete my nutrition data" · V64 — after the server's cascade the phone holds no row, no bodyweight and no queued nutrition op
    func testTheWipeLeavesNoRowNoBodyweightAndNoQueuedOp() throws {
        let (store, queue) = make()
        try NutritionActions.setTargets(bodyweightTenths: 800, unit: "kg", manual: nil, userId: userId, now: at(0), store: store, queue: queue)
        _ = try NutritionActions.quickAdd(MacroGrams(proteinG: 40, carbsG: 0, fatG: 0), userId: userId, timeZone: tz, now: at(1), store: store, queue: queue)
        try NutritionLocal.wipe(userId: userId, store: store)
        XCTAssertNil(try NutritionLocal.targets(for: userId, store: store))
        XCTAssertNil(NutritionTargets.bodyweightOf(nil))
        XCTAssertTrue(try NutritionLocal.logs(for: userId, dayKey: dayKey, store: store).isEmpty)
        XCTAssertTrue(try NutritionLocal.queuedOps(store: store).isEmpty)
    }
}
