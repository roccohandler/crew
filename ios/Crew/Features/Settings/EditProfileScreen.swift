// SPEC: E1 — profile: avatar (tap → Take photo · Choose photo · Remove photo), Name, Save · A7 (owner-directed 2026-09-08) · E5
// (camera denied: one line + Open Settings; the library still works) · Part III law ① (ink acts). Screens hold ZERO logic
// (5.6.6): EditProfileModel holds it. WRITTEN — UNVERIFIED (needs Mac). T041

import SwiftUI

struct EditProfileScreen: View {
    @State private var model = EditProfileModel()
    @State private var showsPhotoChoices = false
    @State private var showsCamera = false
    @State private var showsLibrary = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: EmberTokens.Spacing.space16) {
            Button { showsPhotoChoices = true } label: {
                VStack(spacing: EmberTokens.Spacing.space8) {
                    AvatarView(displayName: model.displayName, image: model.photo, photoKey: model.existingPhotoKey, size: EmberTokens.Size.avatarLarge)
                    Text("Change photo").typeRole(EmberTokens.Typography.textButton).foregroundStyle(EmberColors.ink) // A28 (f): a text button
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change photo")
            if model.cameraDenied {
                Text("Camera's off for Crew. Library photos still work.").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary).multilineTextAlignment(.center)
                // 6.3 — the one route out of a denied camera (E5), at footnote size it was the smallest target on the screen
                TextActionButton(title: "Open Settings", font: .footnote, horizontalPadding: 0, accessibilityLabel: "Open Settings to turn the camera on") { model.openSettings() }
            }
            TextField("Name", text: Binding(get: { model.displayName }, set: { model.setName($0) }))
                .textContentType(.name)
                .typeRole(EmberTokens.Typography.cardSubheading)
                .foregroundStyle(EmberColors.ink)
                .multilineTextAlignment(.center)
                .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt)) // R-083 (11): the platform's field, without field chrome
                .accessibilityLabel("Name")
            if let error = model.errorLine { Text(error).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink) } // A28 (a): red only in a destructive confirm
            // SPEC: A19.5 / R9 — THE SPACER MOVED ABOVE THE SAVE. It was below it, so the only action on the screen sat
            // directly under a one-line name field with the rest of the canvas empty beneath it — the same defect A17.2
            // fixed on Home and R9 fixes everywhere else. 6.7: primary actions stay bottom-anchored.
            Spacer(minLength: 0)
            PrimaryButton(title: "Save", isLoading: model.isSaving) { Task { await model.save(); if model.saved { dismiss() } } }
                .disabled(!model.canSave)
        }
        .padding(.horizontal, EmberTokens.Focus.gutter)
        .padding(.vertical, EmberTokens.Spacing.space24)
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Photo", isPresented: $showsPhotoChoices) {
            if model.cameraAvailable { Button("Take photo") { showsCamera = true } }
            Button("Choose photo") { showsLibrary = true }
            if model.hasPhoto { Button("Remove photo", role: .destructive) { model.removePhoto() } }
        }
        .fullScreenCover(isPresented: $showsCamera) { CameraCapture { image in model.choose(image); showsCamera = false }.ignoresSafeArea() }
        .sheet(isPresented: $showsLibrary) { LibraryPicker { image in model.choose(image); showsLibrary = false } }
    }
}
