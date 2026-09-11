// SPEC: S02 tertiary CTA "Log in" — the login screen is a failure state, not a feature (1C): one screen, email + password,
// a forgot-password line (E18 standard resets), Sign in with Apple for returning Apple users. WRITTEN — UNVERIFIED. T022

import AuthenticationServices
import SwiftUI

struct LoginScreen: View {
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
                .signInWithAppleButtonStyle(.black)
                .frame(height: CGFloat(SpecConstants.dayToggleMinPt))
                AuthField(title: "Email", text: $email, error: nil, contentType: .username, focus: $focused, key: "email", keyboard: .emailAddress) {}
                AuthField(title: "Password", text: $password, error: nil, contentType: .password, focus: $focused, key: "password", secure: true) {}
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
        // SPEC: A19.1 — "Log in" out of the scroll and above the keyboard. It sat under the password field, so on a
        // phone with the keyboard up the field and the button it enables were never on screen together.
        .crewBottomBar {
            PrimaryButton(title: "Log in", isLoading: model.isSaving) { Task { await model.logIn(email: email, password: password) } }
        }
        .background(EmberColors.canvas.ignoresSafeArea())
    }
}
