// SPEC: 5.6.2 OnboardingModel — the auth half: saveWithApple · saveWithEmail · logIn · saveRebuild. After auth the plan is
// saved (the hook becomes the account) and lands on the phone (E6, PlanLocal); a login without a draft pulls the server's
// plan; the invite is honoured (1A); the draft is cleared. A1: the server's plan comes back as trainingWeekdays + workouts
// in rotation order (PlanDTO.draft). Split from OnboardingModel.swift for C9. WRITTEN — UNVERIFIED (needs Mac). T021 + T022

import AuthenticationServices
import Foundation

extension OnboardingModel {
    // SPEC: Flow 8 Rebuild · E4 [Rebuild] — a signed-in user saves straight from the reveal; forward-only, the server copy
    // replaces the phone's (PlanLocal). T042
    func saveRebuild(store: Store = .shared) async {
        guard let draft, let userId = AuthStore.shared.currentUser?.id else { return }
        isSaving = true
        authError = nil
        defer { isSaving = false }
        do {
            let plan = try await Api.shared.putPlan(draft)
            try PlanLocal.replace(plan.draft, userId: userId, updatedAt: plan.updatedAt ?? Date(), store: store)
            rebuildSaved = true
        } catch let error as AppError {
            authError = error.userLine
        } catch {
            authError = AppError.invalidResponse.userLine
        }
    }

    func saveWithEmail(email: String, password: String, displayName: String, birthYear: Int) async {
        await finishSignup {
            let request = RegisterRequestDTO(email: email, password: password, displayName: displayName, timezone: TimeZone.current.identifier, eulaAccepted: true, birthYear: birthYear, measurementSystem: MeasurementSystemHint.current())
            AuthStore.shared.store(try await Api.shared.register(request))
        }
    }

    func saveWithApple(credential: ASAuthorizationAppleIDCredential, birthYear: Int?) async {
        await finishSignup {
            // A9: the measurement system is read inside signInWithApple (it builds the DTO), not passed here — run 34491587098
            // failed on an extra `measurementSystem:` label at this call, the one shape swift-xref could not see until F35
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
                try PlanLocal.replace(plan.draft, userId: userId, updatedAt: plan.updatedAt ?? Date(), store: .shared)
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
