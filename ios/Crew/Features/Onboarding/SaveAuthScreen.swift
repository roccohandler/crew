// SPEC: S05 "Save your plan" — the native Sign in with Apple button (black — it IS the ink system) sits primary; email path
// beneath with .textContentType so Keychain autofills; validation fires on field-exit, never per keystroke; errors are one
// inline line; the plan survives auth failure/abandon (DraftStore). E9: EULA at signup, age floor 13+ (birth year).
// WRITTEN — UNVERIFIED (needs Mac). T022

import AuthenticationServices
import SwiftUI

struct SaveAuthScreen: View {
    @Bindable var model: OnboardingModel
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var birthYear = ""
    @State private var fieldErrors: [String: String] = [:]
    @FocusState private var focused: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Text("Save your plan").font(.title.weight(.bold)).foregroundStyle(EmberColors.inkText)
                Text("The plan is yours. An account is how you keep it.").font(.body).foregroundStyle(EmberColors.secondaryText)
                // SPEC: S05 · 6.1 — `.signUp` because this screen CREATES the account ("Sign up with Apple"); `.signIn` stays
                // on LoginScreen, which recovers one. Every branch of the result is handled: with only `case .success` a
                // cancel, a device carrying no Apple credential and a network failure were one indistinguishable silence, on
                // the screen the whole funnel converges on.
                SignInWithAppleButton(.signUp) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                            model.appleAuthReturnedNoCredential(); return
                        }
                        Task { await model.saveWithApple(credential: credential, birthYear: Int(birthYear)) }
                    case .failure(let error):
                        model.appleAuthFailed(error)
                    }
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: CGFloat(SpecConstants.dayToggleMinPt))
                Text("or with email").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                AuthField(title: "Name", text: $displayName, error: fieldErrors["name"], contentType: .name, focus: $focused, key: "name") { validateName() }
                AuthField(title: "Email", text: $email, error: fieldErrors["email"], contentType: .username, focus: $focused, key: "email", keyboard: .emailAddress) { validateEmail() }
                // .password, not .newPassword: on a signed build iOS answers a .newPassword field with its Automatic Strong Password —
                // the generated text replaces what is typed, and the first signed CI build (run 34373681818) saved one character
                // of the password on every journey. The Keychain still offers to save the pair at signup and autofills it at
                // login (S05); the strong-password suggestion is deferred (docs/debt.md, 2026-09-09).
                AuthField(title: "Password", text: $password, error: fieldErrors["password"], contentType: .password, focus: $focused, key: "password", secure: true) { validatePassword() }
                AuthField(title: "Birth year", text: $birthYear, error: fieldErrors["birthYear"], contentType: .birthdateYear, focus: $focused, key: "birthYear", keyboard: .numberPad) { validateBirthYear() }
                Text("By saving you agree to the terms. Crew is for people \(SpecConstants.minimumAgeYears) and up.").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                if let authError = model.authError { Text(authError).font(.footnote).foregroundStyle(EmberColors.danger) }
            }
            .padding(EmberTokens.Spacing.space24)
        }
        .scrollDismissesKeyboard(.interactively)
        // SPEC: A19.1 — the signup screen's primary, out of the scroll. Five fields plus a legal line at
        // accessibility-XXL put "Save your plan" below the fold on an SE, on the one screen where losing the user
        // costs the account.
        .crewBottomBar {
            PrimaryButton(title: "Save your plan", isLoading: model.isSaving) { submit() }
        }
        // SPEC: A19.2 — the birth-year field is a `.numberPad`, which ships NO RETURN KEY. `scrollDismissesKeyboard`
        // helps only if there is somewhere to scroll; a Done item is the documented remedy and always works.
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = nil }
            }
        }
        .background(EmberColors.canvas.ignoresSafeArea())
    }

    private func validateName() { fieldErrors["name"] = displayName.trimmingCharacters(in: .whitespaces).isEmpty ? "Add a name your crew will recognize." : nil }
    private func validateEmail() { fieldErrors["email"] = email.contains("@") && email.contains(".") ? nil : "That doesn't look like an email." }
    private func validatePassword() { fieldErrors["password"] = password.count < SpecConstants.passwordMinChars ? "At least \(SpecConstants.passwordMinChars) characters." : nil }
    private func validateBirthYear() { fieldErrors["birthYear"] = Int(birthYear) == nil ? "Four digits, like 1994." : nil }

    private func submit() {
        validateName(); validateEmail(); validatePassword(); validateBirthYear()
        guard fieldErrors.isEmpty, let year = Int(birthYear) else { return } // a cleared error is a removed key
        Task { await model.saveWithEmail(email: email, password: password, displayName: displayName.trimmingCharacters(in: .whitespaces), birthYear: year) }
    }
}

struct AuthField: View {
    let title: String
    @Binding var text: String
    let error: String?
    let contentType: UITextContentType
    var focus: FocusState<String?>.Binding
    let key: String
    var keyboard: UIKeyboardType = .default
    var secure = false
    let onExit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
            Group {
                if secure { SecureField(title, text: $text) } else { TextField(title, text: $text) }
            }
            .textContentType(contentType)
            .keyboardType(keyboard)
            .textInputAutocapitalization(key == "name" ? .words : .never)
            .autocorrectionDisabled()
            .focused(focus, equals: key)
            .padding(EmberTokens.Spacing.space12)
            .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
            .background(EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous).stroke(error == nil ? EmberColors.controlOutline : EmberColors.danger, lineWidth: EmberTokens.Size.hairline)) // A18.11: a text field is a control — 3.32:1, never the 1.26:1 hairline
            .onChange(of: focus.wrappedValue) { _, now in if now != key { onExit() } } // validation on field-exit, never per keystroke
            if let error { Text(error).font(.footnote).foregroundStyle(EmberColors.danger) }
        }
    }
}
