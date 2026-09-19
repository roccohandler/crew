// SPEC: S02 tertiary CTA "Log in" — the login screen is a failure state, not a feature (1C): one screen, email + password,
// a forgot-password line (E18 standard resets), Sign in with Apple for returning Apple users. W6 (owner's walkthrough,
// 2026-09-17): reached from the save screen's "Log in instead" with the email PREFILLED (OnboardingModel.prefilledEmail), and the
// return key hops Email → Password → Log in. WRITTEN — UNVERIFIED. T022

import AuthenticationServices
import SwiftUI

struct LoginScreen: View {
    @Environment(\.colorScheme) private var colorScheme // A28 (a): Apple's mandated button style follows the mode (R-083 (11))
    @Bindable var model: OnboardingModel
    @State private var email = ""
    @State private var password = ""
    @State private var resetSent = false
    @FocusState private var focused: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Text("Welcome back").font(.title.weight(.bold)).foregroundStyle(EmberColors.inkText)
                // SPEC: 6.1 — every branch of this result is handled. It used to carry only `case .success`, so a cancel, a
                // device with no Apple credential and a network failure were all indistinguishable from a button that does
                // nothing at all (see OnboardingModel.appleAuthFailed for why Apple cannot tell the first two apart).
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                            model.appleAuthReturnedNoCredential(); return
                        }
                        Task { await model.saveWithApple(credential: credential, birthYear: nil) }
                    case .failure(let error):
                        model.appleAuthFailed(error)
                    }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: CGFloat(SpecConstants.dayToggleMinPt))
                AuthField(title: "Email", text: $email, error: nil, contentType: .username, focus: $focused, key: "email", keyboard: .emailAddress, onSubmit: { focused = "password" }) {}
                AuthField(title: "Password", text: $password, error: nil, contentType: .password, focus: $focused, key: "password", secure: true, onSubmit: { logIn() }) {}
                if let authError = model.authError { Text(authError).font(.footnote).foregroundStyle(EmberColors.danger) }
                Button(resetSent ? "Check your email for the reset link" : "Forgot your password?") {
                    Task { _ = try? await Api.shared.requestPasswordReset(email: email); resetSent = true }
                }
                .font(.footnote)
                .foregroundStyle(EmberColors.inkText)
                .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
            }
            .padding(EmberTokens.Spacing.space24)
        }
        .scrollDismissesKeyboard(.interactively)
        // SPEC: A19.1 — "Log in" out of the scroll and above the keyboard. It sat under the password field, so on a
        // phone with the keyboard up the field and the button it enables were never on screen together.
        .crewBottomBar {
            PrimaryButton(title: "Log in", isLoading: model.isSaving) { logIn() }
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .onAppear { if email.isEmpty { email = model.prefilledEmail } } // W6: what the save screen already knew
    }

    private func logIn() {
        Task { await model.logIn(email: email, password: password) }
    }
}
