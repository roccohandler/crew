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
                    Text("Change photo").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Change photo")
            if model.cameraDenied {
                Text("Camera's off for Crew. Library photos still work.").font(.footnote).foregroundStyle(EmberColors.secondaryText).multilineTextAlignment(.center)
                Button("Open Settings") { model.openSettings() }.font(.footnote).foregroundStyle(EmberColors.inkText)
            }
            TextField("Name", text: Binding(get: { model.displayName }, set: { model.setName($0) }))
                .textContentType(.name)
                .padding(EmberTokens.Spacing.space12)
                .background(EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous))
                .accessibilityLabel("Name")
            if let error = model.errorLine { Text(error).font(.footnote).foregroundStyle(EmberColors.danger) }
            PrimaryButton(title: "Save", isLoading: model.isSaving) { Task { await model.save(); if model.saved { dismiss() } } }
                .disabled(!model.canSave)
                .opacity(model.canSave ? 1 : EmberTokens.Opacity.disabled)
            Spacer()
        }
        .padding(EmberTokens.Spacing.space24)
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
