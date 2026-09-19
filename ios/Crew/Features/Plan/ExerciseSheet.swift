// SPEC: A4 (owner-directed 2026-09-08) · G3 as amended by A28 (f) — the exercise sheet (system §7's sheet on `card`, 28 pt top
// corners): the name at sheet-title weight, the equipment label and the cue line; `Sets` and `Reps` rows with the system's 52 pt
// steppers (long-press repeats), bounds by construction (1…planMaxSetsPerExercise, 1…planTargetRepsMax — nothing invalid is
// reachable); a cardio row shows `Minutes` instead (cardioMinutesStep, A2 — the minutes the user sets, GAP 4). Then text buttons:
// `Swap exercise` (keeps the targets), `Move up` · `Move down` — THE reorder idiom (R-087; the sheet follows the row) — and
// `Remove from {name}` (one tap; Undo lives at the top of the editor). Screens hold zero logic (5.6.6). WRITTEN — UNVERIFIED. R4

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
            .background(EmberColors.card.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { order = nil } } }
        }
        .tint(EmberColors.ink)
        .presentationDetents([.large]) // Remove sat below a medium detent's fold (ui-reviewer, run 35444308817)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(EmberTokens.Focus.cardRadius)
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
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                    Text(row.name).typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    EquipmentLabel(equipment: row.equipment) // A26 in words beside its symbol; a chip is not on A28 (f)'s list (ui-reviewer, run 35444308817)
                    if let cue = model.cueLine(for: row.exerciseId) {
                        Text(cue).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary).fixedSize(horizontal: false, vertical: true)
                    }
                }
                VStack(spacing: 0) {
                    if row.type == "cardio" {
                        StepperRow(label: "Minutes", value: "\(WorkoutDraft.minutes(of: row)) min") { model.adjust(kind: kind, order: order, minutesBy: $0 * SpecConstants.cardioMinutesStep) }
                    } else {
                        StepperRow(label: "Sets", value: "\(row.targetSets)") { model.adjust(kind: kind, order: order, setsBy: $0) }
                        Rectangle().fill(EmberColors.hairlineOnCard).frame(height: EmberTokens.Size.hairline)
                        StepperRow(label: "Reps", value: WorkoutDraft.repsText(row)) { model.adjust(kind: kind, order: order, repsBy: $0) }
                    }
                }
                VStack(alignment: .leading, spacing: 0) {
                    TextActionButton(title: "Swap exercise", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { swapping = true }
                    HStack(spacing: EmberTokens.Spacing.space24) {
                        if model.canReorder(kind: kind, order: order, direction: -1) {
                            TextActionButton(title: "Move up", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { self.order = model.reorder(kind: kind, order: order, direction: -1) ?? order }
                        }
                        if model.canReorder(kind: kind, order: order, direction: 1) {
                            TextActionButton(title: "Move down", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { self.order = model.reorder(kind: kind, order: order, direction: 1) ?? order }
                        }
                    }
                    TextActionButton(title: model.drafts[kind]?.removeTitle ?? "Remove", horizontalPadding: 0, role: EmberTokens.Typography.textButton) {
                        model.remove(kind: kind, order: order)
                        self.order = nil
                    }
                }
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.vertical, EmberTokens.Spacing.space16)
        }
    }
}

// SPEC: A28 (f) — label left, the value as a Rounded Bold numeral, the system's steppers right: which value is changing is never in
// doubt; each step ticks (6.4). At accessibility sizes the steppers drop under the label (§10)
struct StepperRow: View {
    let label: String
    let value: String
    let onStep: (Int) -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: EmberTokens.Spacing.space12) { words; Spacer(minLength: EmberTokens.Spacing.space8); steppers }
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) { words; steppers }
        }
        .padding(.vertical, EmberTokens.Spacing.space12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(label) \(value)")
    }

    private var words: some View {
        HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space8) {
            Text(label).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
            Text(numerals: value).typeRole(EmberTokens.Typography.cardSubheading).foregroundStyle(EmberColors.ink)
        }
    }

    private var steppers: some View {
        HStack(spacing: EmberTokens.Spacing.space12) {
            StepButton(symbol: "minus", noun: label.lowercased(), focus: true) { Haptics.selection(); onStep(-1) } // "Decrease sets"
            StepButton(symbol: "plus", noun: label.lowercased(), focus: true) { Haptics.selection(); onStep(1) }
        }
    }
}
// A26: EquipmentChip and EquipmentLabel live in Shared/EquipmentChip.swift — the reveal draws the chip; this sheet and the swap lists the label
