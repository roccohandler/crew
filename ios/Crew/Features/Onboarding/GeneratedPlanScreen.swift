// SPEC: S04 — renders < 500 ms; every exercise shows equipment chip + targets + the mobility block; Swap in 2 taps;
// Full-Body A/B at ≤2 days. 1C — the reveal is the onboarding's peak: day cards stagger in over ~0.5 s ("Your week,
// built."), instant under Reduce Motion; the swap whisper appears once. Ink-on-bone only. WRITTEN — UNVERIFIED. T021

import SwiftUI

struct GeneratedPlanScreen: View {
    @Bindable var model: OnboardingModel
    let onLooksGood: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = 0
    @State private var swapping: (weekday: Int, exerciseId: String)?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Text("Your week, built.").font(.title.weight(.bold)).foregroundStyle(EmberColors.inkText)
                if !model.swapWhisperShown {
                    Text("Tap any exercise to swap it.").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                }
                ForEach(Array((model.draft?.workouts ?? []).enumerated()), id: \.element.weekday) { index, workout in
                    DayCard(workout: workout) { exerciseId in
                        model.swapWhisperShown = true
                        swapping = (workout.weekday, exerciseId)
                    }
                    .opacity(index < revealed ? 1 : 0)
                }
                PrimaryButton(title: "Looks good") { model.acceptPlan(); onLooksGood() }
            }
            .padding(EmberTokens.Spacing.space24)
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .onAppear { reveal() }
        .sheet(isPresented: Binding(get: { swapping != nil }, set: { if !$0 { swapping = nil } })) {
            if let swapping {
                SwapSheet(candidates: model.swapCandidates(for: swapping.exerciseId)) { replacement in
                    model.swap(exerciseId: swapping.exerciseId, in: swapping.weekday, with: replacement)
                    self.swapping = nil
                }
            }
        }
    }

    // ~0.5 s total stagger across the day cards; instant under Reduce Motion (6.4)
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

struct DayCard: View {
    let workout: PlanDraftWorkout
    let onTapExercise: (String) -> Void
    private let weekdayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                Text("\(weekdayNames[workout.weekday - 1]) · \(workout.name)").font(.headline).foregroundStyle(EmberColors.inkText)
                ForEach(workout.exercises.filter { $0.type == "strength" }, id: \.exerciseId) { row in
                    Button { onTapExercise(row.exerciseId) } label: { ExerciseRow(row: row) }.buttonStyle(.plain)
                }
                let holds = workout.exercises.filter { $0.type == "mobility" }
                if !holds.isEmpty {
                    Text("Mobility · \(holds.count) holds").font(.subheadline.weight(.semibold)).foregroundStyle(EmberColors.secondaryText)
                    ForEach(holds, id: \.exerciseId) { hold in
                        Text("\(hold.name) · \(hold.holdSeconds ?? 0)s\((hold.perSide ?? false) ? " each" : "")").font(.subheadline).foregroundStyle(EmberColors.secondaryText)
                    }
                }
            }
        }
    }
}

struct ExerciseRow: View {
    let row: PlanDraftExercise

    private var targets: String {
        if let max = row.targetRepsMax { return "\(row.targetSets)×\(row.targetReps)–\(max)" }
        return "\(row.targetSets)×\(row.targetReps)"
    }

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space8) {
            Text(row.name).font(.body).foregroundStyle(EmberColors.inkText)
            Spacer()
            Text(row.equipment.capitalized).font(.caption).foregroundStyle(EmberColors.secondaryText)
                .padding(.horizontal, EmberTokens.Spacing.space8).padding(.vertical, EmberTokens.Spacing.space4)
                .overlay(Capsule().stroke(EmberColors.hairline, lineWidth: EmberTokens.Size.hairline))
            Text(targets).font(.subheadline.monospacedDigit()).foregroundStyle(EmberColors.inkText)
        }
        .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Double-tap to swap")
    }
}
