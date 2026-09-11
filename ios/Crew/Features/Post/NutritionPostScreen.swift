// SPEC: S11 Nutrition post — [+] → live camera < 1 s; library available; time-smart tag pre-selected; text-only ≤ 3 taps; "same
// as yesterday" chip when applicable; optimistic post < 500 ms; states: permission-denied (E5 → text-first), error.
// WRITTEN — UNVERIFIED (needs Mac). T027

import SwiftUI

struct NutritionPostScreen: View {
    let onPosted: () -> Void
    @State private var model = PostModel(cameraAvailable: CameraCapture.isAvailable)
    @State private var showsCamera = CameraCapture.isAvailable
    @State private var showsLibrary = false
    @Environment(\.dismiss) private var dismiss
    private var hasCrew: Bool { (try? Store.shared.crewSnapshot()) != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                    if !CameraCapture.isAvailable {
                        Text("Camera's off for Crew — text posts count just the same. Turn it on in Settings whenever.").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                    }
                    HStack(spacing: EmberTokens.Spacing.space12) {
                        if CameraCapture.isAvailable { SecondaryButton(title: model.photo == nil ? "Snap" : "Retake") { showsCamera = true } }
                        SecondaryButton(title: "Library") { showsLibrary = true }
                    }
                    PostComposer(model: model, hasCrew: hasCrew)
                    if let error = model.submitError { Text(error).font(.footnote).foregroundStyle(EmberColors.danger) }
                }
                .padding(EmberTokens.Spacing.space16)
            }
            // SPEC: A19.1 / A19.2 — "Post" sat UNDER the caption field inside the scroll, which is the shape 6.7 names
            // twice: a bottom CTA that is neither above the home indicator nor reachable while the keyboard is up.
            // `safeAreaInset` fixes both at once — the bar rises above the keyboard rather than being covered by it,
            // so the caption and the button it enables are on screen together for the first time.
            .crewBottomBar {
                PrimaryButton(title: "Post") { model.submit() }
                    .disabled(!model.canSubmit)
                    .opacity(model.canSubmit ? 1 : EmberTokens.Opacity.disabled)
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .fullScreenCover(isPresented: $showsCamera) { CameraCapture { image in model.photo = image ?? model.photo; showsCamera = false }.ignoresSafeArea() }
            .sheet(isPresented: $showsLibrary) { LibraryPicker { image in model.photo = image ?? model.photo; showsLibrary = false } }
            .onChange(of: model.posted) { _, posted in if posted { onPosted() } }
        }
    }
}
