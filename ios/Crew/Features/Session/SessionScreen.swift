// SPEC: S09 Session — one-tap set logging at pre-fill; ghost row after every set; warm-ups excluded from x/y; mobility holds
// countdown + auto-check; survives kill (every tap saves); Complete always visible; skips gray; out-of-order works; VoiceOver-
// complete; screen stays awake (Flow 3). 6.7: Complete visible without scrolling on the SE at XXL. WRITTEN — UNVERIFIED. T025

import SwiftUI

struct SessionScreen: View {
    @State private var model: SessionModel
    let onCompleted: (CelebrationOutcome) -> Void
    @State private var cue: String?
    @State private var showsDiscard = false
    @State private var swapping: LocalSessionExercise?
    @State private var replacement: SeedExercise?
    @Environment(\.dismiss) private var dismiss

    init(session: LocalSession, onCompleted: @escaping (CelebrationOutcome) -> Void) {
        _model = State(initialValue: SessionModel(session: session))
        self.onCompleted = onCompleted
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                    ForEach(Array(model.exercises.enumerated()), id: \.element.order) { index, exercise in
                        exerciseCard(exercise, isFocused: index == model.focusIndex)
                    }
                    RestTimerView(timer: model.restTimer)
                    Button("Discard workout") { showsDiscard = true }.font(.footnote).foregroundStyle(EmberColors.secondaryText).frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                }
                .padding(EmberTokens.Spacing.space16)
            }
            VStack(spacing: EmberTokens.Spacing.space8) {
                if let error = model.completeError { Text(error).font(.footnote).foregroundStyle(EmberColors.secondaryText) }
                PrimaryButton(title: "Complete workout") { model.complete(shareToCrew: true) } // always visible, bottom-anchored
            }
            .padding(EmberTokens.Spacing.space16)
            .background(EmberColors.canvas)
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle(model.session.workoutName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false; model.saveForLater() }
        .onChange(of: model.celebration) { _, outcome in if let outcome { onCompleted(outcome) } }
        .alert(cue ?? "", isPresented: Binding(get: { cue != nil }, set: { if !$0 { cue = nil } })) { Button("Got it") {} }
        .confirmationDialog("Discard this workout?", isPresented: $showsDiscard) {
            Button("Discard", role: .destructive) { model.discard(); dismiss() }
        }
        .sheet(item: $swapping) { exercise in
            SwapSheet(candidates: model.swapCandidates(for: exercise)) { pick in replacement = pick } // E7: two taps, then one question
        }
        .confirmationDialog(replacement.map { "\($0.name) — for how long?" } ?? "", isPresented: Binding(get: { replacement != nil }, set: { if !$0 { replacement = nil } })) {
            Button("Just today") { if let swapping, let replacement { model.swap(swapping, with: replacement, scope: .today) }; swapping = nil; replacement = nil }
            Button("Update my plan") { if let swapping, let replacement { model.swap(swapping, with: replacement, scope: .plan) }; swapping = nil; replacement = nil }
            Button("Keep it", role: .cancel) { swapping = nil; replacement = nil }
        }
    }

    @ViewBuilder
    private func exerciseCard(_ exercise: LocalSessionExercise, isFocused: Bool) -> some View {
        Card {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                HStack {
                    Button { cue = SeedCatalog.shared.exercise(exercise.exerciseId)?.cueLine } label: {
                        Text(exercise.name).font(.headline).foregroundStyle(exercise.skipped ? EmberColors.missedGray : EmberColors.inkText)
                    }.buttonStyle(.plain)
                    Spacer()
                    Text(exercise.equipment.capitalized).font(.caption).foregroundStyle(EmberColors.secondaryText)
                    if exercise.type == "strength", !exercise.skipped {
                        Button("Swap") { swapping = exercise }.font(.caption).foregroundStyle(EmberColors.secondaryText).accessibilityLabel("Swap \(exercise.name)")
                    }
                    Button(exercise.skipped ? "Unskip" : "Skip") { model.skip(exercise) }.font(.caption).foregroundStyle(EmberColors.secondaryText)
                }
                if let last = model.lastTimeLine(for: exercise) { Text(last).font(.caption).foregroundStyle(EmberColors.secondaryText) }
                if isFocused && !exercise.skipped { rows(exercise) }
                else if !exercise.skipped { Button("Open") { model.jumpTo(exercise) }.font(.subheadline).foregroundStyle(EmberColors.inkText) }
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func rows(_ exercise: LocalSessionExercise) -> some View {
        let sets = model.sets(of: exercise)
        let firstOpen = sets.firstIndex { !$0.done && !$0.isWarmup }
        ForEach(Array(sets.enumerated()), id: \.element.order) { index, set in
            if exercise.type == "mobility" {
                MobilityHoldRow(name: exercise.name, set: set, perSide: SeedCatalog.shared.exercise(exercise.exerciseId)?.perSide ?? false) { model.finishHold(set) }
            } else {
                SetRow(exerciseName: exercise.name, equipment: exercise.equipment, set: set, index: sets[...index].filter { !$0.isWarmup }.count, count: sets.filter { !$0.isWarmup }.count, units: model.units,
                       isGhost: firstOpen.map { index > $0 } ?? false,
                       onCheck: { model.checkSet(set, in: exercise) }, onReps: { model.adjustReps(set, by: $0) }, onWeight: { model.adjustWeight(set, by: $0) })
            }
        }
        if exercise.type == "strength" {
            HStack(spacing: EmberTokens.Spacing.space16) {
                Button("+ set") { if let last = sets.last { model.addSet(after: last, in: exercise) } }
                Button("+ warm-up") { model.addWarmup(to: exercise) }
            }
            .font(.subheadline).foregroundStyle(EmberColors.inkText).frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
        }
    }
}
