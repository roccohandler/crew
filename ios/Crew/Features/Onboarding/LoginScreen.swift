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
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    if case .success(let authorization) = result, let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                        Task { await model.saveWithApple(credential: credential, birthYear: nil) }
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: CGFloat(SpecConstants.dayToggleMinPt))
                AuthField(title: "Email", text: $email, error: nil, contentType: .username, focus: $focused, key: "email", keyboard: .emailAddress) {}
                AuthField(title: "Password", text: $password, error: nil, contentType: .password, focus: $focused, key: "password", secure: true) {}
                if let authError = model.authError { Text(authError).font(.footnote).foregroundStyle(EmberColors.danger) }
                PrimaryButton(title: "Log in", isLoading: model.isSaving) { Task { await model.logIn(email: email, password: password) } }
                Button(resetSent ? "Check your email for the reset link" : "Forgot your password?") {
                    Task { _ = try? await Api.shared.requestPasswordReset(email: email); resetSent = true }
                }
                .font(.footnote)
                .foregroundStyle(EmberColors.inkText)
                .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
            }
            .padding(EmberTokens.Spacing.space24)
        }
        .background(EmberColors.canvas.ignoresSafeArea())
    }
}
