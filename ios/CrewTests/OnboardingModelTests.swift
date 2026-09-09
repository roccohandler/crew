// SPEC: T021 + T022 (Verify: ios tests) · S03 (Mon/Wed/Fri pre-selected; Continue needs ≥1 day; auto-advance; the neutral
// whisper) · S04 (Swap in two taps, keyed by workout kind — A1) · A1 (the reveal is this week's projection: seven rows,
// rest days named, every planned day carries a workout of the cycle) · S05 (the draft survives abandon and resumes at the
// save screen). WRITTEN — UNVERIFIED (needs Mac).

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
        XCTAssertEqual(DayToggle.whisper, "Most people start at 3 days.")
        for day in Array(model.selectedDays) { model.toggleDay(day) }
        XCTAssertFalse(model.canContinueFromDays)
        model.toggleDay(2)
        XCTAssertTrue(model.canContinueFromDays)
        XCTAssertEqual(model.encouragementLine, "1 day a week — a start is a start.")
        model.toggleDay(4)
        XCTAssertEqual(model.encouragementLine, "2 days a week — solid.") // A1: no full-body line at two days
    }

    func testAnswersBuildAPlanAndSwapReplacesOneExercise() {
        let model = OnboardingModel(draftStore: temporaryStore())
        model.continueFromDays()
        model.choose(experience: "brandNew")
        XCTAssertEqual(model.step, .equipment)
        model.choose(equipment: "fullGym")
        XCTAssertEqual(model.step, .reveal)
        let draft = try! XCTUnwrap(model.draft)
        XCTAssertEqual(draft.trainingWeekdays, SpecConstants.defaultTrainingWeekdays)
        XCTAssertEqual(draft.workouts.map(\.kind), ["push", "pull", "legs"])
        let first = draft.workouts[0]
        let incumbent = first.exercises.first { $0.type == "strength" }!
        let candidates = model.swapCandidates(for: incumbent.exerciseId)
        XCTAssertGreaterThanOrEqual(candidates.count, SpecConstants.swapCandidatesMin)
        model.swap(exerciseId: incumbent.exerciseId, in: first.kind, with: candidates[0])
        let swapped = model.draft!.workouts[0].exercises[incumbent.order]
        XCTAssertEqual(swapped.exerciseId, candidates[0].id)
        XCTAssertEqual(swapped.order, incumbent.order)
        XCTAssertEqual(model.draft!.workouts[1], draft.workouts[1]) // the other workouts are untouched
        XCTAssertEqual(model.draft!.trainingWeekdays, draft.trainingWeekdays)
    }

    // SPEC: A1 — the reveal projects this week: seven rows Mon..Sun; a rest row on every unselected day; every planned row
    // names a workout of the cycle; Push · Pull · Legs at one day a week too
    func testRevealProjectsThisWeekForAnyDayCount() {
        let model = OnboardingModel(draftStore: temporaryStore())
        for day in Array(model.selectedDays) { model.toggleDay(day) }
        model.toggleDay(6)
        model.choose(experience: "some")
        model.choose(equipment: "bodyweight")
        XCTAssertEqual(model.draft?.workouts.map(\.kind), ["push", "pull", "legs"])
        XCTAssertEqual(model.weekRows.map(\.weekday), Array(1...TimeUnits.daysPerWeek))
        for row in model.weekRows where row.weekday != 6 { XCTAssertTrue(row.title.hasSuffix(" · Rest"), row.title) }
        let saturday = model.weekRows[5]
        XCTAssertTrue(saturday.title.hasPrefix("Sat · "), saturday.title)
        if let kind = saturday.kind {
            XCTAssertEqual(kind, "push") // a fresh cycle starts at its first workout
            XCTAssertEqual(saturday.title, "Sat · Push day")
            XCTAssertEqual(saturday.detail, "\(SpecConstants.someExperienceExerciseCount) exercises + mobility")
        } else {
            XCTAssertEqual(saturday.title, "Sat · —") // already past this week: open, no word
        }
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
        XCTAssertEqual(resumed.weekRows, model.weekRows)
        XCTAssertEqual(resumed.experience, "some")
        store.clear()
        XCTAssertNil(store.load())
    }
}
