// SPEC: A4 (owner-directed 2026-09-08) · G3 — the exercise sheet (.medium detent): name + equipment chip + cue line;
// `Sets` and `Reps` steppers with ≥ 44 pt segments (the app's Stepper: long-press repeats), bounds by construction
// (1…planMaxSetsPerExercise, 1…planTargetRepsMax — the model refuses nothing because nothing invalid is reachable); a
// cardio row shows a `Minutes` stepper instead (cardioMinutesStep, A2); `Swap exercise` (keeps the targets), `Move up` ·
// `Move down` (the sheet follows the row), `Remove from {name}` (one tap; Undo lives in the editor's snackbar).
// Screens hold zero logic (5.6.6). Ink on bone. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct ExerciseSheet: View {
    let model: PlanModel
    let kind: String
    @Binding var order: Int?
    @State private var swapping = false

    var body: some View {
        NavigationStack {
            Group {
                if let order, let row = model.drafts[kind]?.row(order: order) { content(order: order, row: row) } else { EmptyView() }
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { order = nil } } }
        }
        .tint(EmberColors.inkText)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $swapping) {
            SwapSheet(candidates: order.map { model.swapCandidates(kind: kind, order: $0) } ?? []) { pick in
                if let order { model.swap(kind: kind, order: order, with: pick) }
                swapping = false
            }
        }
    }

    private func content(order: Int, row: PlanDraftExercise) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Text(row.name).font(.title2.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                EquipmentChip(equipment: row.equipment)
                if let cue = model.cueLine(for: row.exerciseId) { Text(cue).font(.subheadline).foregroundStyle(EmberColors.secondaryText) }
                if row.type == "cardio" {
                    StepperRow(label: "Minutes", value: "\(WorkoutDraft.minutes(of: row)) min") { model.adjust(kind: kind, order: order, minutesBy: $0 * SpecConstants.cardioMinutesStep) }
                } else {
                    StepperRow(label: "Sets", value: "\(row.targetSets)") { model.adjust(kind: kind, order: order, setsBy: $0) }
                    StepperRow(label: "Reps", value: WorkoutDraft.repsText(row)) { model.adjust(kind: kind, order: order, repsBy: $0) }
                }
                SecondaryButton(title: "Swap exercise") { swapping = true }
                HStack(spacing: EmberTokens.Spacing.space12) {
                    SecondaryButton(title: "Move up") { self.order = model.reorder(kind: kind, order: order, direction: -1) ?? order }
                        .disabled(!model.canReorder(kind: kind, order: order, direction: -1))
                        .opacity(model.canReorder(kind: kind, order: order, direction: -1) ? 1 : EmberTokens.Opacity.disabled)
                    SecondaryButton(title: "Move down") { self.order = model.reorder(kind: kind, order: order, direction: 1) ?? order }
                        .disabled(!model.canReorder(kind: kind, order: order, direction: 1))
                        .opacity(model.canReorder(kind: kind, order: order, direction: 1) ? 1 : EmberTokens.Opacity.disabled)
                }
                Button(model.drafts[kind]?.removeTitle ?? "Remove") {
                    model.remove(kind: kind, order: order)
                    self.order = nil
                }
                .font(.headline)
                .foregroundStyle(EmberColors.inkText)
                .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                .padding(.top, EmberTokens.Spacing.space8)
            }
            .padding(EmberTokens.Spacing.space24)
        }
    }
}

// Label left, value centre, ± segments right — which value is changing is never in doubt; each step ticks (6.4)
struct StepperRow: View {
    let label: String
    let value: String
    let onStep: (Int) -> Void

    var body: some View {
        HStack {
            Text(label).font(.body).foregroundStyle(EmberColors.inkText)
            Spacer()
            Stepper(label: value) { delta in
                Haptics.selection()
                onStep(delta)
            }
        }
        .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(label) \(value)")
    }
}

struct EquipmentChip: View {
    let equipment: String

    var body: some View {
        Text(equipment.capitalized)
            .font(.caption)
            .foregroundStyle(EmberColors.secondaryText)
            .padding(.horizontal, EmberTokens.Spacing.space8)
            .padding(.vertical, EmberTokens.Spacing.space4)
            .overlay(Capsule().stroke(EmberColors.hairline, lineWidth: EmberTokens.Size.hairline))
    }
}
