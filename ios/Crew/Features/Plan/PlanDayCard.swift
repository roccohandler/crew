// SPEC: S14 — one day at a glance: tap the name to swap, steppers for sets/reps (limits by construction), ↑ ↓ reorder, remove,
// add; mobility holds read-only (Flow 3: duration only). Plain helpers of the Plan feature (5.6.6). WRITTEN — UNVERIFIED. S14 iOS

import SwiftUI

struct PlanDayCard: View {
    let slot: DaySlot
    let model: PlanModel
    let onSwap: (PlanDraftExercise) -> Void
    let onAdd: () -> Void
    private let weekdayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                if let workout = slot.workout {
                    Text("\(weekdayNames[slot.weekday - 1]) · \(workout.name)").font(.headline).foregroundStyle(EmberColors.inkText)
                    ForEach(workout.exercises, id: \.exerciseId) { row in
                        if row.type == "strength" {
                            PlanExerciseRow(row: row, weekday: slot.weekday, model: model, onSwap: { onSwap(row) })
                        } else {
                            Text("\(row.name) · Mobility · \(row.holdSeconds ?? 0)s\((row.perSide ?? false) ? " each" : "")").font(.subheadline).foregroundStyle(EmberColors.secondaryText)
                        }
                    }
                    if workout.exercises.count < SpecConstants.planMaxExercisesPerDay {
                        Button("+ Add exercise", action: onAdd).font(.subheadline.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                    }
                } else {
                    Text("\(weekdayNames[slot.weekday - 1]) · Rest").font(.headline).foregroundStyle(EmberColors.secondaryText)
                }
            }
        }
    }
}

struct PlanExerciseRow: View {
    let row: PlanDraftExercise
    let weekday: Int
    let model: PlanModel
    let onSwap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
            HStack {
                Button(row.name, action: onSwap).font(.body.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                    .accessibilityLabel("\(row.name), \(row.equipment). Swap")
                Spacer()
                Text(row.equipment).font(.caption).foregroundStyle(EmberColors.secondaryText)
            }
            HStack(spacing: EmberTokens.Spacing.space12) {
                PlanStepper(label: "\(row.targetSets) sets", name: "sets for \(row.name)") { model.adjust(exerciseId: row.exerciseId, in: weekday, setsBy: $0) }
                PlanStepper(label: "\(row.targetReps) reps", name: "reps for \(row.name)") { model.adjust(exerciseId: row.exerciseId, in: weekday, repsBy: $0) }
                Spacer()
                Button("↑") { model.reorder(exerciseId: row.exerciseId, in: weekday, direction: -1) }.accessibilityLabel("Move \(row.name) up")
                Button("↓") { model.reorder(exerciseId: row.exerciseId, in: weekday, direction: 1) }.accessibilityLabel("Move \(row.name) down")
                Button("Remove", role: .destructive) { model.remove(exerciseId: row.exerciseId, in: weekday) }.accessibilityLabel("Remove \(row.name)")
            }
            .font(.footnote)
            .foregroundStyle(EmberColors.inkText)
        }
    }
}

struct PlanStepper: View {
    let label: String
    let name: String
    let onStep: (Int) -> Void

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space4) {
            Button("−") { onStep(-1) }.accessibilityLabel("Decrease \(name)")
            Text(label).foregroundStyle(EmberColors.inkText)
            Button("+") { onStep(1) }.accessibilityLabel("Increase \(name)")
        }
        .buttonStyle(.bordered)
        .tint(EmberColors.inkText)
    }
}
