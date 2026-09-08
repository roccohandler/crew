// SPEC: T021 + T022 (Verify: ios tests) · S03 (Mon/Wed/Fri pre-selected; Continue needs ≥1 day; auto-advance) · S04 (Swap in
// two taps) · S05 (the draft survives abandon and resumes at the save screen). WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class OnboardingModelTests: XCTestCase {
    private func temporaryStore() -> DraftStore {
        DraftStore(url: FileManager.default.temporaryDirectory.appending(path: "draft-\(UUID().uuidString).json"))
    }

    func testDefaultsAndDayToggling() {
        let model = OnboardingModel(draftStore: temporaryStore())
        XCTAssertEqual(model.selectedDays, Set(SpecConstants.defaultTrainingWeekdays))
        XCTAssertEqual(model.encouragementLine, "3 days a week — solid.")
        for day in Array(model.selectedDays) { model.toggleDay(day) }
        XCTAssertFalse(model.canContinueFromDays)
        model.toggleDay(2)
        XCTAssertTrue(model.canContinueFromDays)
    }

    func testAnswersBuildAPlanAndSwapReplacesOneExercise() {
        let model = OnboardingModel(draftStore: temporaryStore())
        model.continueFromDays()
        model.choose(experience: "brandNew")
        XCTAssertEqual(model.step, .equipment)
        model.choose(equipment: "fullGym")
        XCTAssertEqual(model.step, .reveal)
        let draft = try! XCTUnwrap(model.draft)
        XCTAssertEqual(draft.workouts.map(\.kind), ["push", "pull", "legs"])
        let first = draft.workouts[0]
        let incumbent = first.exercises.first { $0.type == "strength" }!
        let candidates = model.swapCandidates(for: incumbent.exerciseId)
        XCTAssertGreaterThanOrEqual(candidates.count, SpecConstants.swapCandidatesMin)
        model.swap(exerciseId: incumbent.exerciseId, in: first.weekday, with: candidates[0])
        let swapped = model.draft!.workouts[0].exercises[incumbent.order]
        XCTAssertEqual(swapped.exerciseId, candidates[0].id)
        XCTAssertEqual(swapped.order, incumbent.order)
    }

    func testDraftSurvivesAbandonAndResumesAtSave() {
        let store = temporaryStore()
        let model = OnboardingModel(draftStore: store)
        model.choose(experience: "some")
        model.choose(equipment: "dumbbells")
        model.acceptPlan()
        let resumed = OnboardingModel(draftStore: store)
        XCTAssertEqual(resumed.step, .save)
        XCTAssertEqual(resumed.draft, model.draft)
        XCTAssertEqual(resumed.experience, "some")
        store.clear()
        XCTAssertNil(store.load())
    }
}
