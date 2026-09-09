// SPEC: 5.6.2 OnboardingModel — state: step, selectedDays, experience?, equipment?, draft, weekRows, authError?; actions:
// toggleDay · choose(experience) auto-advance · choose(equipment) · regenerate · swap (by workout kind, A1) · saveWithApple ·
// saveWithEmail (OnboardingModelAuth.swift); the draft persists locally pre-auth (S05: the plan survives auth failure/
// abandon). 1A invite-aware fast path (the crew token rides through onboarding; after auth the user lands INSIDE the
// crew). A1 (owner-directed 2026-09-08): the reveal shows THIS week's rotation projection — Push · Pull · Legs at every
// day count. C14 (@Observable, plain vars). WRITTEN — UNVERIFIED (needs Mac). T021 + T022

import Foundation
import Observation

enum OnboardingStep: Equatable {
    case hero, days, experience, equipment, reveal, save, login
}

// signup = Flow 1 (hero → questions → reveal → save); rebuild = Flow 8 / E4 for a signed-in user (questions → reveal → saved)
enum OnboardingMode: Equatable {
    case signup, rebuild
}

@Observable
@MainActor
final class OnboardingModel {
    var step: OnboardingStep = .hero
    var selectedDays: Set<Int> = Set(SpecConstants.defaultTrainingWeekdays)   // 1B: Mon/Wed/Fri pre-selected
    var experience: String?
    var equipment: String?
    var draft: PlanDraft?
    var weekRows: [WeekMapRow] = []   // A1: this week's projection of the draft (`Mon · Push day` …)
    var authError: String?
    var isSaving = false
    var invitedCrew: CrewPreviewDTO?
    var inviteToken: String?
    var swapWhisperShown = false   // 1C: the "Tap any exercise to swap it." whisper appears once, then never again

    let mode: OnboardingMode
    var rebuildSaved = false

    let seed: SeedCatalog
    let draftStore: DraftStore
    private let store: Store?      // rebuild only: the rotation pointer comes from the phone's completed sessions (A1)
    private let timeZone: TimeZone

    init(seed: SeedCatalog = .shared, draftStore: DraftStore = DraftStore(), mode: OnboardingMode = .signup, store: Store? = nil, timeZone: TimeZone = .current) {
        self.seed = seed
        self.draftStore = draftStore
        self.mode = mode
        self.store = store
        self.timeZone = timeZone
        if mode == .signup, let saved = draftStore.load() {
            selectedDays = saved.selectedDays
            experience = saved.experience
            equipment = saved.equipment
            draft = saved.draft
            inviteToken = saved.inviteToken
            step = .save   // S05: resumes here next launch
            refreshWeekRows()
        }
    }

    // 1B: the encouragement line reads live under the day picker (A1: no full-body line — every count rotates PPL)
    var encouragementLine: String {
        switch selectedDays.count {
        case 0: return "Pick at least one day."
        case 1: return "1 day a week — a start is a start."
        default: return "\(selectedDays.count) days a week — solid."
        }
    }

    var canContinueFromDays: Bool { selectedDays.count >= SpecConstants.minTrainingDaysToContinue }

    func toggleDay(_ weekday: Int) {
        if selectedDays.contains(weekday) { selectedDays.remove(weekday) } else { selectedDays.insert(weekday) }
    }

    func continueFromDays() {
        guard canContinueFromDays else { return }
        step = .experience
    }

    // 1B: single-select answers auto-advance: selection haptic → 250 ms beat → next screen (the screen schedules the beat)
    func choose(experience value: String) {
        experience = value
        step = .equipment
    }

    func choose(equipment value: String) {
        equipment = value
        regenerate()
        step = .reveal
    }

    func regenerate() {
        guard let experience, let equipment else { return }
        draft = PlanGenerator.generatePlan(days: selectedDays, experience: experience, access: equipment, seed: seed)
        refreshWeekRows()
    }

    // SPEC: A1 · S04 — the reveal is this week's projection: a signup starts the cycle at its first workout; a rebuild
    // continues from the last completed rotation workout on the phone, so nobody repeats a day they just did
    func refreshWeekRows(now: Date = Date()) {
        guard let draft, !draft.workouts.isEmpty else { weekRows = []; return }
        let cycle = draft.workouts.map(\.kind)
        var last: String?
        if mode == .rebuild, let userId = AuthStore.shared.currentUser?.id {
            last = (try? (store ?? .shared).lastCompletedRotationKind(for: userId, cycle: cycle)) ?? nil
        }
        let todayKey = DayKey.dayKey(for: now, tz: timeZone)
        let next = PlanRotation.nextWorkoutKind(lastCompletedKind: last, cycle: cycle)
        let week = PlanRotation.projectWeek(weekKey: DayKey.weekKey(for: todayKey), todayKey: todayKey, trainingWeekdays: draft.trainingWeekdays, cycle: cycle, nextKind: next, completedKindByDay: [:])
        weekRows = week.map { WeekMapRow.make($0, workouts: draft.workouts) }
    }

    func swapCandidates(for exerciseId: String) -> [SeedExercise] {
        guard let incumbent = seed.exercise(exerciseId), let equipment else { return [] }
        return SwapFinder.swapCandidates(for: incumbent, access: equipment, experience: experience ?? "brandNew", seed: seed)
    }

    // Flow 1 step 4 — two taps, no questions asked, ever; the row keeps its order (A1: workouts are keyed by kind)
    func swap(exerciseId: String, in kind: String, with replacement: SeedExercise) {
        guard let draft, let experience else { return }
        let workouts = draft.workouts.map { workout -> PlanDraftWorkout in
            guard workout.kind == kind else { return workout }
            let exercises = workout.exercises.map { row -> PlanDraftExercise in
                guard row.exerciseId == exerciseId else { return row }
                return PlanGenerator.strengthRow(replacement.id, experience: experience, order: row.order, seed: seed) ?? row
            }
            return PlanDraftWorkout(name: workout.name, kind: workout.kind, exercises: exercises)
        }
        self.draft = PlanDraft(trainingWeekdays: draft.trainingWeekdays, workouts: workouts)
    }

    func acceptPlan() {
        guard mode == .signup else { return } // a rebuild saves from the reveal (saveRebuild); the pre-auth draft is never touched
        persistDraft()
        step = .save
    }

    func persistDraft() {
        draftStore.save(OnboardingDraft(selectedDays: selectedDays, experience: experience, equipment: equipment, draft: draft, inviteToken: inviteToken))
    }
}
