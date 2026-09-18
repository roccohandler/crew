// SPEC: 1C ("profile photo prompted at first crew join — skippable") / W4 (owner-approved 2026-09-17) — once per account, on the
// first Crew screen with a crew and no photo: one line, Add a photo (EditProfileScreen holds the picker, E1) or Not now. The flag is
// set by a join or a create (OnboardingModelAuth.finishSignup, CrewModel.join/joinByCode/create) and consumed by CrewScreen once.
// Twin of web PhotoPrompt.tsx. Ink acts (Part III law ①); an invitation, never a nag (6.1). WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

enum PhotoPromptFlag {
    private static let key = "profilePhotoPromptPending"

    static func markPending() { UserDefaults.standard.set(true, forKey: key) }

    // Consumed once; true only for an account that still has no photo
    @MainActor static func consume() -> Bool {
        guard UserDefaults.standard.bool(forKey: key) else { return false }
        UserDefaults.standard.removeObject(forKey: key)
        return AuthStore.shared.currentUser?.profilePhotoKey == nil
    }
}

struct ProfilePhotoPrompt: View {
    let onDone: () -> Void
    @State private var editing = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Spacer()
                Text("Add a photo so your crew knows it's you.").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                Text("It shows on your posts and in the member strip. Only your crew sees it.").font(.body).foregroundStyle(EmberColors.secondaryText)
                Spacer()
                PrimaryButton(title: "Add a photo") { editing = true }
                Button("Not now", action: onDone)
                    .font(.body)
                    .foregroundStyle(EmberColors.inkText)
                    .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
            }
            .padding(EmberTokens.Spacing.space24)
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationDestination(isPresented: $editing) { EditProfileScreen().onDisappear(perform: onDone) }
        }
    }
}
