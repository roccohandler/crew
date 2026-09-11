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

    // SPEC: 6.1 ("Error: what happened + what to do, one sentence, no codes, always a retry path. Never a dead end.") · S05 ·
    // 1C (the email path is the recovery, and it is already on screen beneath the button).
    //
    // Both auth screens handled ONLY `case .success`, so every Apple failure was indistinguishable from a button that does
    // nothing. That is worst for the user who has no Apple credential to offer: `ASAuthorizationError.canceled` is returned
    // BOTH when the person cancels AND when the system finds no credential — Apple returns one code for both deliberately, so
    // as not to reveal what is on the device — and that user could tap forever and never learn why. Because the two cases are
    // indistinguishable the line must serve both: it states the fact without blaming anyone who cancelled on purpose, and it
    // names the two ways forward. No code, no "sorry", no exclamation (6.6).
    func appleAuthFailed(_ error: Error) {
        isSaving = false
        guard (error as? ASAuthorizationError)?.code != .unknown else { authError = nil; return } // dismissed before the sheet drew anything
        authError = appleAuthLine(for: error)
    }

    // Credentials that are not an Apple ID credential (a password credential from the Keychain, say) reach the same dead end
    func appleAuthReturnedNoCredential() {
        isSaving = false
        authError = "Nothing came back from Apple. Try again, or use email below."
    }

    private func appleAuthLine(for error: Error) -> String {
        guard let authorizationError = error as? ASAuthorizationError else { return "Apple couldn't sign you in. Try again, or use email below." }
        switch authorizationError.code {
        case .canceled: return "Nothing came back from Apple. Try again, or use email below."
        default: return "Apple couldn't sign you in. Try again, or use email below."
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
