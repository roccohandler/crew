// SPEC: S04 — renders < 500 ms; every exercise shows equipment chip + targets + the mobility block; Swap in 2 taps.
// A1 (owner-directed 2026-09-08): "Your week, built." then THIS week's projection (`Mon · Push day` …) and the line
// "Every workout rotates in, so each gets equal time." — Push · Pull · Legs at every day count, keyed by kind. 1C — the
// reveal is the onboarding's peak: workout cards stagger in over ~0.5 s, instant under Reduce Motion; the swap whisper
// appears once. A rebuild that cannot save says so here (never a silent no-op). Ink-on-bone only. WRITTEN — UNVERIFIED. T021

import SwiftUI

struct GeneratedPlanScreen: View {
    @Bindable var model: OnboardingModel
    let onLooksGood: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = 0
    @State private var swapping: (kind: String, order: Int, exerciseId: String)? // A26: the ROW (order) — an exercise id may name several

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Text("Your week, built.").font(.title.weight(.bold)).foregroundStyle(EmberColors.inkText)
                if model.mode == .signup { Whisper(.whyPpl) } // A23: never in a sheet — a rebuild is one (rule 3)
                VStack(spacing: EmberTokens.Spacing.space8) {
                    ForEach(model.weekRows) { row in WeekRow(row: row, interactive: false) {} }
                }
                Text("Every workout rotates in, so each gets equal time.").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                if model.mode == .signup { Whisper(.howRevealSwap) } // 1C's one whisper, now part of the A23 system: once per account
                ForEach(Array((model.draft?.workouts ?? []).enumerated()), id: \.element.kind) { index, workout in
                    WorkoutCard(workout: workout) { row in
                        swapping = (workout.kind, row.order, row.exerciseId)
                    }
                    .opacity(index < revealed ? 1 : 0)
                }
                if let line = model.authError { Text(line).font(.footnote).foregroundStyle(EmberColors.inkText) }
            }
            .padding(EmberTokens.Spacing.space24)
        }
        // SPEC: A19.1 — the first adoption of `.crewBottomBar`, and the lowest-risk of the six: this screen sits
        // outside journeys ①② and has exactly one primary. "Looks good" used to be the last row INSIDE the scroll, so
        // on a seven-workout plan at accessibility-XXL the only way out of onboarding was below the fold. The bar
        // holds it above the home indicator whatever the plan's length, and the scroll view insets itself so the last
        // workout card is never trapped underneath it.
        .crewBottomBar {
            PrimaryButton(title: "Looks good", isLoading: model.isSaving) { model.acceptPlan(); onLooksGood() }
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .onAppear { reveal() }
        .sheet(isPresented: Binding(get: { swapping != nil }, set: { if !$0 { swapping = nil } })) {
            if let swapping {
                SwapSheet(candidates: model.swapCandidates(for: swapping.exerciseId)) { replacement in
                    model.swap(order: swapping.order, in: swapping.kind, with: replacement)
                    self.swapping = nil
                }
            }
        }
    }

    // ~0.5 s total stagger across the workout cards; instant under Reduce Motion (6.4)
    private func reveal() {
        let count = model.draft?.workouts.count ?? 0
        guard !reduceMotion, count > 0 else { revealed = count; return }
        let step = Double(SpecConstants.planRevealStaggerMs) / Double(count) / Double(TimeUnits.msPerSecond)
        for index in 0..<count {
            DispatchQueue.main.asyncAfter(deadline: .now() + step * Double(index)) {
                withAnimation(.crewSpring) { revealed = index + 1 }
            }
        }
    }
}

// One workout of the cycle (A1): its name, the strength rows (tap to swap), the mobility block that closes it
struct WorkoutCard: View {
    let workout: PlanDraftWorkout
    let onTapExercise: (PlanDraftExercise) -> Void

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                Text(workout.name).font(.headline).foregroundStyle(EmberColors.inkText)
                // A26: keyed by ORDER — the owner's Pull repeats the rope curl, and a repeated id is not an identity
                ForEach(workout.exercises.filter { $0.type == "strength" }, id: \.order) { row in
                    Button { onTapExercise(row) } label: { ExerciseRow(row: row) }.buttonStyle(.plain)
                }
                let holds = workout.exercises.filter { $0.type == "mobility" }
                if !holds.isEmpty {
                    Text("Mobility · \(holds.count) holds").font(.subheadline.weight(.semibold)).foregroundStyle(EmberColors.secondaryText)
                    ForEach(holds, id: \.exerciseId) { hold in
                        Text(WorkoutDraft.holdLine(hold)).font(.subheadline).foregroundStyle(EmberColors.secondaryText)
                    }
                }
            }
        }
    }
}

struct ExerciseRow: View {
    let row: PlanDraftExercise

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space8) {
            Text(row.name).font(.body).foregroundStyle(EmberColors.inkText)
            Spacer()
            EquipmentChip(equipment: row.equipment)
            Text("\(row.targetSets)×\(WorkoutDraft.repsText(row))").font(.subheadline.monospacedDigit()).foregroundStyle(EmberColors.inkText)
        }
        .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double-tap to swap")
    }
}
