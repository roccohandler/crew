// SPEC: 5.6.2 OnboardingModel — state: step, selectedDays, experience?, draft, weekRows, authError?; actions: toggleDay ·
// choose(experience) auto-advance (A21.1, owner-approved 2026-09-17: the experience answer is the LAST question and builds
// the plan — the equipment question and choose(equipment) are gone because every user has full commercial gym access) ·
// regenerate · swap (by workout kind, A1) · saveWithApple · saveWithEmail (OnboardingModelAuth.swift); the draft persists
// locally pre-auth (S05: the plan survives auth failure/abandon). 1A invite-aware fast path (the crew token rides through
// onboarding; after auth the user lands INSIDE the crew). A21.3 / W4 (owner-approved 2026-09-17): the token arrives as a PASTED
// CODE — hero "I have an invite" → InviteCodeScreen → lookUpInvite (GET crews/join, public) → the preview line → the two
// questions; a dead code and a full crew are explicit states (S13). A1 (owner-directed 2026-09-08): the reveal shows THIS week's
// rotation projection — Push · Pull · Legs at every day count. C14 (@Observable, plain vars). WRITTEN — UNVERIFIED. T021 + T022

import Foundation
import Observation

enum OnboardingStep: Equatable {
    case hero, inviteCode, days, experience, reveal, save, login
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
    var draft: PlanDraft?
    var weekRows: [WeekMapRow] = []   // A1: this week's projection of the draft (`Mon · Push day` …)
    var authError: String?
    var isSaving = false
    var invitedCrew: CrewPreviewDTO?
    var inviteToken: String?
    var swapWhisperShown = false   // 1C: the "Tap any exercise to swap it." whisper appears once, then never again
    var inviteCode = ""            // A21.3: what the person pasted — the bare code or the whole link (InviteCode.token reads it)
    var inviteError: String?       // S13: dead code · full crew · not a code — one line, always a way forward
    var isLookingUpInvite = false

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

    // SPEC: A21.3 · S13 — the pasted code is the crew's inviteToken; the public preview names the crew ("Dawn Patrol 🌅 · 3 of 10
    // in the crew"); a dead code reads the server's line, a full crew its own; the token rides through onboarding only once it is live
    func lookUpInvite() async {
        inviteError = nil
        invitedCrew = nil
        inviteToken = nil
        guard let token = InviteCode.token(from: inviteCode) else { inviteError = "That doesn't look like an invite code. Paste the code or the whole link."; return }
        isLookingUpInvite = true
        defer { isLookingUpInvite = false }
        do {
            let preview = try await Api.shared.crewPreview(token: token)
            invitedCrew = preview
            if preview.full { inviteError = "Crew full — \(SpecConstants.crewMaxMembers) is the max. Ask about a second crew." } else { inviteToken = token }
        } catch let error as AppError {
            inviteError = error.userLine
        } catch {
            inviteError = AppError.invalidResponse.userLine
        }
    }
    // 1B: single-select answers auto-advance: selection haptic → 250 ms beat → next screen (the screen schedules the beat).
    // SPEC: A21.1 — experience is the last question, so the answer builds the plan and the next screen is the reveal
    func choose(experience value: String) {
        experience = value
        regenerate()
        step = .reveal
    }

    func regenerate() {
        guard let experience else { return }
        draft = PlanGenerator.generatePlan(days: selectedDays, experience: experience, seed: seed)
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
        guard let incumbent = seed.exercise(exerciseId) else { return [] }
        return SwapFinder.swapCandidates(for: incumbent, experience: experience ?? "brandNew", seed: seed)
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
        draftStore.save(OnboardingDraft(selectedDays: selectedDays, experience: experience, draft: draft, inviteToken: inviteToken))
    }
}
