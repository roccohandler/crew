// SPEC: S09 Session as amended by A28 (c), (d), (f) (owner-approved 2026-09-19; design/targets 07–10) — THE LOGGER, ONE SET PER
// SCREEN: a header (back, the workout's name, ⋯), the segmented workout bar, the count and "Whole workout", then either the SET
// SCREEN (the exercise, one card of two metric rows, the fact line; "Swap exercise" and "Skip" as text; one filled "Log set N") or,
// on the holds, the CHECKLIST (its one filled button is Finish). The whole-workout sheet carries Finish too (R-083 (21)); "+ set",
// "+ warm-up", set removal and Discard live under ⋯, Discard behind its destructive confirm (the one place red appears). No timers
// (A28 (c)): no rest countdown, no hold countdown, no session clock. Kept: the tab bar hidden (A21.11), every tap saves, the back
// chevron leaves with the session open, the screen stays awake (Flow 3), E7's swap. WRITTEN — UNVERIFIED (needs Mac). T025 · R2

import SwiftUI

struct SessionScreen: View {
    @State private var model: SessionModel
    let onCompleted: (CelebrationOutcome) -> Void
    @State private var cue: String?
    @State private var showsDiscard = false
    @State private var showsMore = false
    @State private var showsSheet = false
    @State private var finishingFromSheet = false
    @State private var swapping: LocalSessionExercise?
    @State private var replacement: SeedExercise?
    @State private var typing = TypedField.reps // what the keypad types: kept after the alert closes, so its Set button reads it
    @State private var showsKeypad = false
    @State private var typed = ""
    @State private var plateLine: String?
    @Environment(\.dismiss) private var dismiss

    init(session: LocalSession, onCompleted: @escaping (CelebrationOutcome) -> Void) {
        _model = State(initialValue: SessionModel(session: session))
        self.onCompleted = onCompleted
    }

    private var displayed: LocalSetLog? { model.focused.flatMap { model.displayedSet(of: $0) } }

    var body: some View {
        // Mockups 07 and 08 centre the exercise, the card and the fact line between the bar and the bottom group; the screen still
        // scrolls when Dynamic Type makes the set taller than the phone (§10)
        GeometryReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                WorkoutBar(model: model)
                HStack(spacing: EmberTokens.Spacing.space12) {
                    Text(numerals: model.countLine).typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.inkSecondary)
                    Spacer(minLength: EmberTokens.Spacing.space8)
                    Button { showsSheet = true } label: {
                        HStack(spacing: EmberTokens.Spacing.space4) {
                            Text("Whole workout").typeRole(EmberTokens.Typography.textButton)
                            Image(systemName: "chevron.down").font(.caption.weight(.bold))
                        }
                        .foregroundStyle(EmberColors.ink)
                        .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Whole workout")
                }
                Spacer(minLength: EmberTokens.Spacing.space32)
                content
                Spacer(minLength: EmberTokens.Spacing.space24)
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .frame(minHeight: proxy.size.height, alignment: .top)
        }
        }
        .toolbarRole(.editor) // the back button is the bare chevron the mockups draw, never "‹ Back"
        // A19.1 — the bottom group is a real inset: it rises above the keyboard and nothing scrolls under it (6.7: "Log set" and Finish
        // visible without scrolling at the SE at accessibility-XXL)
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle(model.session.workoutName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar) // A21.11: a session owns the screen; the tabs return with Finish or Discard
        .toolbar { ToolbarItem(placement: .topBarTrailing) { menu } }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false; model.saveForLater() }
        .onChange(of: model.celebration) { _, outcome in if let outcome, !finishingFromSheet { onCompleted(outcome) } }
        .onChange(of: model.focusIndex) { _, _ in plateLine = nil }
        .alert(cue ?? "", isPresented: Binding(get: { cue != nil }, set: { if !$0 { cue = nil } })) { Button("Got it") {} }
        .alert(typing.title(units: model.units, distanceUnit: model.distanceUnit), isPresented: $showsKeypad) {
            TextField(typing.title(units: model.units, distanceUnit: model.distanceUnit), text: $typed).keyboardType(typing.wholeNumber ? .numberPad : .decimalPad)
            Button("Set") { commitTyped() }
            Button("Cancel", role: .cancel) { typed = "" }
        }
        .confirmationDialog("Discard this workout?", isPresented: $showsDiscard, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { model.discard(); dismiss() } // A28 (a): red only here, inside the confirm
        }
        .sheet(isPresented: $showsSheet, onDismiss: { if finishingFromSheet, let outcome = model.celebration { onCompleted(outcome) } }) {
            WholeWorkoutSheet(model: model, onJump: { model.jumpTo($0); showsSheet = false }) {
                finishingFromSheet = true
                model.complete()
                if model.celebration != nil { showsSheet = false } else { finishingFromSheet = false }
            }
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
    private var content: some View {
        if model.isOnChecklist {
            MobilityChecklist(model: model)
        } else if let exercise = model.focused, let set = displayed {
            SetScreenBody(model: model, exercise: exercise, setLog: set, plateLine: plateLine,
                          onCue: { cue = SeedCatalog.shared.exercise(exercise.exerciseId)?.cueLine },
                          onTypeReps: { begin(.reps, "\(set.actualReps)") },
                          onTypeWeight: { begin(.weight, set.weight.map { model.formatted($0).split(separator: " ").first.map(String.init) ?? "" } ?? "") },
                          onTypeMinutes: { begin(.minutes, "\(model.cardioMinutes(of: set, in: exercise))") },
                          onTypeDistance: { begin(.distance, "") })
        }
    }

    // SPEC: A28 (d) — Swap exercise and Skip as text, then the ONE filled button: "Log set N" on the set screen, Finish on the checklist
    private var bottomBar: some View {
        VStack(spacing: EmberTokens.Spacing.space8) {
            if !model.isOnChecklist, let exercise = model.focused {
                Whisper(.howSwapSkip) // A23: the first time a session opens
                HStack(spacing: EmberTokens.Spacing.space24) {
                    if exercise.type == "strength", !exercise.skipped {
                        TextActionButton(title: "Swap exercise", role: EmberTokens.Typography.textButton) { swapping = exercise }
                    }
                    TextActionButton(title: exercise.skipped ? "Unskip" : "Skip", accessibilityLabel: exercise.skipped ? "Unskip \(exercise.name)" : "Skip \(exercise.name)", role: EmberTokens.Typography.textButton) { model.skip(exercise) }
                }
            }
            if let error = model.completeError, !showsSheet { Text(error).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink) }
            if model.isOnChecklist {
                PrimaryButton(title: "Finish workout") { model.complete() }
            } else if let exercise = model.focused, !exercise.skipped, let set = displayed {
                PrimaryButton(title: set.isWarmup ? "Log warm-up" : "Log set \(model.setNumber(set, in: exercise))") { log(set, in: exercise) }
            }
        }
        .padding(.horizontal, EmberTokens.Focus.gutter)
        .padding(.vertical, EmberTokens.Spacing.space12)
        .background(EmberColors.canvas)
    }

    // SPEC: A28 (d) — "+ set", "+ warm-up", set removal (A11: absent on the last work set, V55) and its undo, plate math on demand, and
    // Discard, under ⋯ so Swap and Skip stay visible (system §9). An action sheet, not a context menu: its words take the app's ink,
    // where a menu's are the platform's black (ui-reviewer, run 35444308817)
    private var menu: some View {
        Button { showsMore = true } label: {
            Image(systemName: "ellipsis").font(.body.weight(.semibold)).foregroundStyle(EmberColors.ink)
                .frame(width: CGFloat(SpecConstants.minTouchTargetPt), height: CGFloat(SpecConstants.minTouchTargetPt))
        }
        .accessibilityLabel("More")
        .confirmationDialog("More", isPresented: $showsMore, titleVisibility: .hidden) {
            if let exercise = model.focused, exercise.type == "strength", !exercise.skipped {
                Button("+ set") { model.addSet(to: exercise) }.accessibilityLabel("Add a set")
                Button("+ warm-up") { model.addWarmup(to: exercise) }.accessibilityLabel("Add a warm-up set")
                if let set = displayed, model.canRemove(set, in: exercise) {
                    Button(set.isWarmup ? "Remove this warm-up" : "Remove set \(model.setNumber(set, in: exercise))") { model.removeSet(set, in: exercise) }
                }
                if exercise.equipment == "barbell", let weight = displayed?.weight {
                    Button("Show the plates") { plateLine = PlateMath.plateLine(totalWeight: weight, units: model.units) }
                }
            }
            if model.lastRemoved != nil { Button("Undo the removal") { model.undoRemove(in: model.exercises) } }
            Button("Discard workout") { showsDiscard = true }
        }
    }

    private func log(_ set: LocalSetLog, in exercise: LocalSessionExercise) {
        plateLine = nil
        if exercise.type == "cardio" { model.logCardio(set, in: exercise) } else { model.logSet(set, in: exercise) }
        if model.nothingOpen { showsSheet = true } // every exercise done or skipped: what is left is Finish, and Finish lives there
    }

    private func begin(_ field: TypedField, _ current: String) {
        typed = current
        typing = field
        showsKeypad = true
    }

    // SPEC: Flow 3 "invalid values impossible" — a typed number is clamped (and a weight snapped) by the model on commit
    private func commitTyped() {
        defer { typed = "" }
        guard let exercise = model.focused, let set = displayed,
              let value = Double(typed.replacingOccurrences(of: ",", with: ".")) else { return }
        switch typing {
        case .reps: model.setReps(set, to: Int(value))
        case .weight: model.setWeight(set, to: value)
        case .minutes: model.setCardioMinutes(set, to: Int(value), in: exercise)
        case .distance: model.setDistance(set, to: value)
        }
    }
}
