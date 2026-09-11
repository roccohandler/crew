// SPEC: 5.6.6 (a screen branches only on view state; every trigger and every consequence lives in the model) · C10
// (one screen per file — this is Home's prompt layer, not Home). Split from HomeScreen.swift for the C9 200-line cap.
// WRITTEN — UNVERIFIED (needs Mac). T042

import SwiftUI

// SPEC: T042 — the three edge prompts, in priority order: welcome back (E4, full screen) → stale session (S01) → held uploads (E19).
// Screens branch only on view state; every trigger and every consequence lives in HomeModel (5.6.6).
struct EdgePrompts: ViewModifier {
    let model: HomeModel
    let onKeepGoing: () -> Void
    let onRebuild: () -> Void

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: Binding(get: { model.welcomeBack }, set: { _ in })) {
                WelcomeBackScreen(longestStreak: model.longestStreak, onKeep: { Task { await model.acknowledgeWelcomeBack() } }, onRebuild: { Task { await model.acknowledgeWelcomeBack(); onRebuild() } })
            }
            .sheet(isPresented: Binding(get: { !model.welcomeBack && model.staleSession != nil }, set: { _ in })) {
                StaleSessionPrompt(workoutName: model.staleSession?.workoutName ?? "Your workout", onKeepGoing: onKeepGoing, onDiscard: { model.discardStaleSession() })
            }
            .sheet(isPresented: Binding(get: { !model.welcomeBack && model.staleSession == nil && !model.heldUploads.isEmpty }, set: { _ in })) {
                FailedUploadSheet(records: model.heldUploads) { model.resolveUpload($0, choice: $1) }
            }
    }
}
