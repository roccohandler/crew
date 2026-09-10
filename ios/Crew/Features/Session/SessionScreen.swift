// SPEC: S09 Session — one-tap set logging at pre-fill; ghost row after every set; warm-ups excluded from x/y; mobility holds
// countdown + auto-check; survives kill (every tap saves); Complete always visible; skips gray; out-of-order works; VoiceOver-
// complete; screen stays awake (Flow 3). 6.7: Complete visible without scrolling on the SE at XXL. A2 (owner-directed
// 2026-09-08): a cardio block renders a CardioRow (minutes + optional distance, Done). WRITTEN — UNVERIFIED. T025

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
                    // A9: the units question, asked once at the first moment it matters — never a modal, never blocking
                    if !model.unitsConfirmed {
                        UnitConfirmLine(weightUnit: model.units, onKeep: { model.confirmUnits() }, onFlip: { Task { await model.flipUnits() } })
                    }
                    ForEach(Array(model.exercises.enumerated()), id: \.element.order) { index, exercise in
                        exerciseCard(exercise, isFocused: index == model.focusIndex)
                    }
                    // SPEC: A11 — "Set removed · Undo", the same shape the plan editor's remove already uses (A4). It stays
                    // until the next removal or the workout ends; no timer, because a row that vanishes on a clock is a row
                    // you cannot get back (the editor's snackbar has the same deliberate omission, logged in debt.md).
                    if model.lastRemoved != nil {
                        HStack {
                            Text("Set removed").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                            Spacer()
                            Button("Undo") { model.undoRemove(in: model.exercises) }
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(EmberColors.inkText)
                                .frame(minWidth: CGFloat(SpecConstants.minTouchTargetPt), minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                                .contentShape(Rectangle())
                        }
                        .padding(.horizontal, EmberTokens.Spacing.space12)
                        .background(EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous))
                    }
                    Button("Discard workout") { showsDiscard = true }.font(.footnote).foregroundStyle(EmberColors.secondaryText).frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                }
                .padding(EmberTokens.Spacing.space16)
            }
            VStack(spacing: EmberTokens.Spacing.space8) {
                Text(model.liveSummaryLine).font(.footnote.monospacedDigit()).foregroundStyle(EmberColors.secondaryText) // S09 · A2: the live count, cardio appended
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
                        // SPEC: 6.5 (text ≥ 4.5:1) · Flow 3 ("skips gray") — a skipped name is quieter but still readable.
                        // It used missedGray (#A8A29A), which measures 2.53:1 on a white card and fails the gate outright;
                        // missedGray is a SHAPE colour (ring segments, heat-map cells), and secondaryText is the token the
                        // system already designates for de-emphasised text. Still visibly gray, now legible.
                        Text(exercise.name).font(.headline).foregroundStyle(exercise.skipped ? EmberColors.secondaryText : EmberColors.inkText)
                            .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true) // 6.7: a long name wraps; it never pushes Swap and Skip past a 375-pt edge
                    }.buttonStyle(.plain)
                    Spacer(minLength: EmberTokens.Spacing.space8)
                    Text(exercise.equipment.capitalized).font(.caption).foregroundStyle(EmberColors.secondaryText)
                    if exercise.type == "strength", !exercise.skipped {
                        Button("Swap") { swapping = exercise }.font(.caption).foregroundStyle(EmberColors.secondaryText).accessibilityLabel("Swap \(exercise.name)")
                    }
                    Button(exercise.skipped ? "Unskip" : "Skip") { model.skip(exercise) }.font(.caption).foregroundStyle(EmberColors.secondaryText)
                }
                if let last = model.lastTimeLine(for: exercise) { Text(last).font(.caption).foregroundStyle(EmberColors.secondaryText) }
                if isFocused && !exercise.skipped {
                    rows(exercise)
                    RestTimerView(timer: model.restTimer) // Flow 3: the countdown lives with the exercise that started it
                }
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
                MobilityHoldRow(name: exercise.name, setLog: set, perSide: SeedCatalog.shared.exercise(exercise.exerciseId)?.perSide ?? false) { model.finishHold(set) }
            } else if exercise.type == "cardio" { // A2: minutes + optional distance, Done
                CardioRow(name: exercise.name, setLog: set, targetSeconds: exercise.holdSeconds ?? set.holdSeconds ?? 0, distanceUnit: model.distanceUnit) { model.finishCardio(set, minutes: $0, distanceMeters: $1) }
            } else {
                // A11: swipe reveals Remove; the engine refuses on the last work set (V55) so the gesture is disabled there
                SwipeToRemove(isEnabled: model.canRemove(set, in: exercise), label: set.isWarmup ? "warm-up" : "set \(sets[...index].filter { !$0.isWarmup }.count)", onRemove: { model.removeSet(set, in: exercise) }) {
                SetRow(exerciseName: exercise.name, equipment: exercise.equipment, set: set, index: sets[...index].filter { !$0.isWarmup }.count, count: sets.filter { !$0.isWarmup }.count, units: model.units,
                       isGhost: firstOpen.map { index > $0 } ?? false,
                       isOpen: firstOpen == index, // A10: the tape belongs to the set you are on
                       canRemove: model.canRemove(set, in: exercise), // A11: absent on the last work set (V55)
                       onSetWeight: { model.setWeight(set, to: $0) },
                       onRemove: { model.removeSet(set, in: exercise) },
                       onCheck: { model.checkSet(set, in: exercise) }, onReps: { model.adjustReps(set, by: $0) }, onWeight: { model.adjustWeight(set, by: $0) })
                }
            }
        }
        if exercise.type == "strength" {
            // SPEC: 6.3 — each of these is its own ≥ 44 pt target. The minHeight used to sit on the enclosing HStack,
            // which sizes the ROW but leaves each bare Button's hit rect at its text box (~40×18 pt and ~76×18 pt) —
            // the owner's "the hit boxes feel too small". A frame plus contentShape on the LABEL is what moves the target.
            HStack(spacing: EmberTokens.Spacing.space16) {
                SetCountButton(title: "+ set", accessibilityLabel: "Add a set to \(exercise.name)") { if let last = sets.last { model.addSet(after: last, in: exercise) } }
                SetCountButton(title: "+ warm-up", accessibilityLabel: "Add a warm-up set to \(exercise.name)") { model.addWarmup(to: exercise) }
            }
        }
    }
}
