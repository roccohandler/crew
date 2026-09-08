// SPEC: Flow 1 — hero → three questions → reveal → save; every arrival type has its path on screen one (1A); back-swipe
// preserves every answer (1B: NavigationStack keeps the model). Screens branch only on view state (5.6.6).
// WRITTEN — UNVERIFIED (needs Mac). T021 + T022

import SwiftUI

struct OnboardingFlow: View {
    @State private var model: OnboardingModel
    @State private var path: [OnboardingStep] = []
    private let mode: OnboardingMode
    private let onRebuilt: () -> Void

    // rebuild (Flow 8 / E4): a signed-in user starts at the questions and the reveal saves the plan (T042)
    init(mode: OnboardingMode = .signup, onRebuilt: @escaping () -> Void = {}) {
        self.mode = mode
        self.onRebuilt = onRebuilt
        _model = State(initialValue: OnboardingModel(mode: mode))
    }

    var body: some View {
        NavigationStack(path: $path) {
            root
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .days: DaysQuestionScreen(model: model) { path.append(.experience) }
                    case .experience: ExperienceQuestionScreen(model: model) { path.append(.equipment) }
                    case .equipment: EquipmentQuestionScreen(model: model) { path.append(.reveal) }
                    case .reveal: GeneratedPlanScreen(model: model) { afterReveal() }
                    case .save: SaveAuthScreen(model: model)
                    case .login: LoginScreen(model: model)
                    case .hero: EmptyView()
                    }
                }
        }
        .tint(EmberColors.inkText)
        .onAppear { if model.step == .save { path = [.days, .experience, .equipment, .reveal, .save] } } // S05 resume
    }

    @ViewBuilder private var root: some View {
        if mode == .rebuild {
            DaysQuestionScreen(model: model) { path.append(.experience) }
        } else {
            IntroScreen(
                invitedCrewLine: model.invitedCrew.map { "\($0.name) \($0.emoji) is waiting for you" },
                onBuildMyWeek: { path = [.days] },
                onHaveInvite: { path = [.days] },
                onLogIn: { path = [.login] }
            )
        }
    }

    private func afterReveal() {
        guard mode == .rebuild else { path.append(.save); return }
        Task { await model.saveRebuild(); if model.rebuildSaved { onRebuilt() } }
    }
}
