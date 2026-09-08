// SPEC: 5.6.2 OnboardingModel — state: step, selectedDays, experience?, equipment?, draft, authError?; actions: toggleDay ·
// choose(experience) auto-advance · choose(equipment) · regenerate · swap · saveWithApple · saveWithEmail; the draft
// persists locally pre-auth (S05: the plan survives auth failure/abandon). 1A invite-aware fast path (the crew token
// rides through onboarding; after auth the user lands INSIDE the crew). C14 (@Observable, plain vars).
// WRITTEN — UNVERIFIED (needs Mac). T021 + T022

import AuthenticationServices
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
    var authError: String?
    var isSaving = false
    var invitedCrew: CrewPreviewDTO?
    var inviteToken: String?
    var swapWhisperShown = false   // 1C: the "Tap any exercise to swap it." whisper appears once, then never again

    let mode: OnboardingMode
    var rebuildSaved = false

    private let seed: SeedCatalog
    private let draftStore: DraftStore

    init(seed: SeedCatalog = .shared, draftStore: DraftStore = DraftStore(), mode: OnboardingMode = .signup) {
        self.seed = seed
        self.draftStore = draftStore
        self.mode = mode
        if mode == .signup, let saved = draftStore.load() {
            selectedDays = saved.selectedDays
            experience = saved.experience
            equipment = saved.equipment
            draft = saved.draft
            inviteToken = saved.inviteToken
            step = .save   // S05: resumes here next launch
        }
    }

    // 1B: the encouragement line reads live under the day picker
    var encouragementLine: String {
        switch selectedDays.count {
        case 0: return "Pick at least one day."
        case 1: return "1 day a week — a start is a start."
        case SpecConstants.fullBodyMaxTrainingDays: return "2 days a week — full body, done right."
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
    }

    func swapCandidates(for exerciseId: String) -> [SeedExercise] {
        guard let incumbent = seed.exercise(exerciseId), let equipment else { return [] }
        return SwapFinder.swapCandidates(for: incumbent, access: equipment, experience: experience ?? "brandNew", seed: seed)
    }

    // Flow 1 step 4 — two taps, no questions asked, ever
    func swap(exerciseId: String, in weekday: Int, with replacement: SeedExercise) {
        guard var draft, let experience else { return }
        draft = PlanDraft(workouts: draft.workouts.map { workout in
            guard workout.weekday == weekday else { return workout }
            let exercises = workout.exercises.map { row -> PlanDraftExercise in
                guard row.exerciseId == exerciseId else { return row }
                return PlanGenerator.strengthRow(replacement.id, experience: experience, order: row.order, seed: seed) ?? row
            }
            return PlanDraftWorkout(weekday: workout.weekday, name: workout.name, kind: workout.kind, exercises: exercises)
        })
        self.draft = draft
    }

    func acceptPlan() {
        guard mode == .signup else { return } // a rebuild saves from the reveal (saveRebuild); the pre-auth draft is never touched
        persistDraft()
        step = .save
    }

    func persistDraft() {
        draftStore.save(OnboardingDraft(selectedDays: selectedDays, experience: experience, equipment: equipment, draft: draft, inviteToken: inviteToken))
    }

    // SPEC: Flow 8 Rebuild · E4 [Rebuild] — a signed-in user saves straight from the reveal; forward-only, the server copy
    // replaces the phone's (PlanLocal). T042
    func saveRebuild(store: Store = .shared) async {
        guard let draft, let userId = AuthStore.shared.currentUser?.id else { return }
        isSaving = true
        authError = nil
        defer { isSaving = false }
        do {
            let plan = try await Api.shared.putPlan(draft)
            try PlanLocal.replace(plan.workouts, userId: userId, updatedAt: plan.updatedAt ?? Date(), store: store)
            rebuildSaved = true
        } catch let error as AppError {
            authError = error.userLine
        } catch {
            authError = AppError.invalidResponse.userLine
        }
    }

    func saveWithEmail(email: String, password: String, displayName: String, birthYear: Int) async {
        await finishSignup {
            let request = RegisterRequestDTO(email: email, password: password, displayName: displayName, timezone: TimeZone.current.identifier, eulaAccepted: true, birthYear: birthYear)
            AuthStore.shared.store(try await Api.shared.register(request))
        }
    }

    func saveWithApple(credential: ASAuthorizationAppleIDCredential, birthYear: Int?) async {
        await finishSignup {
            try await AuthStore.shared.signInWithApple(credential: credential, timezone: TimeZone.current, eulaAccepted: true, birthYear: birthYear)
        }
    }

    func logIn(email: String, password: String) async {
        await finishSignup {
            AuthStore.shared.store(try await Api.shared.login(LoginRequestDTO(email: email, password: password)))
        }
    }

    // After auth: the plan is saved (the hook becomes the account) and lands on the phone (E6); a login without a draft pulls the
    // server's plan; the invite is honoured; the draft is cleared
    private func finishSignup(_ authenticate: () async throws -> Void) async {
        isSaving = true
        authError = nil
        defer { isSaving = false }
        do {
            try await authenticate()
            let userId = AuthStore.shared.currentUser?.id ?? "local"
            if let draft {
                let plan = try await Api.shared.putPlan(draft)
                try PlanLocal.replace(plan.workouts, userId: userId, updatedAt: plan.updatedAt ?? Date(), store: .shared)
            } else {
                await ServerHydrate.pullIfEmpty(userId: userId, store: .shared) // a login on a fresh phone: plan, journal, sessions, gamification, crew
            }
            if let inviteToken { _ = try? await Api.shared.joinCrew(token: inviteToken) }
            draftStore.clear()
        } catch let error as AppError {
            authError = error.userLine
        } catch {
            authError = AppError.invalidResponse.userLine
        }
    }
}
