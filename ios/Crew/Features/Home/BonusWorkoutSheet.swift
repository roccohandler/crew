// SPEC: A3 (owner-directed 2026-09-08) — Bonus workout: a sheet listing the plan's workouts, the next rotation workout first
// and labelled "Next up"; starting one creates a session with isPlannedDay false on a rest or done day (+25, V30/V31 — never
// expected, Flow 5). A8: no XP promise in the CTA, orange only on rewards. Part III law ①: every row is ink. A28 (f): the
// system's sheet — `card`, the title in the content at `sheetTitle` with Cancel beside it, row buttons on the gutter
// (ui-reviewer, run 35444308817: a canvas sheet under a navigation bar's small title). Branches only on view state (5.6.6); the
// order comes from HomeModel.bonusWorkouts. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct BonusWorkoutSheet: View {
    let workouts: [LocalWorkoutTemplate]   // next up first
    let onPick: (LocalWorkoutTemplate) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space12) {
                    Text("Bonus workout").typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: EmberTokens.Spacing.space8)
                    TextActionButton(title: "Cancel", role: EmberTokens.Typography.textButton) { dismiss() } // 6.3: the pull has a visible twin
                }
                VStack(spacing: 0) {
                    ForEach(Array(workouts.enumerated()), id: \.element.kind) { index, workout in
                        if index > 0 { Rectangle().fill(EmberColors.hairlineOnCard).frame(height: EmberTokens.Size.hairline) }
                        Button { onPick(workout) } label: { row(workout, isNext: index == 0) }
                            .buttonStyle(.plain)
                    }
                }
                // Flow 5's words; A28 (e): no imperative outside a button label
                Text("A bonus workout is never expected.").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.top, EmberTokens.Spacing.space32)
            .padding(.bottom, EmberTokens.Spacing.space24)
        }
        .background(EmberColors.card.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(EmberTokens.Focus.cardRadius)
        .tint(EmberColors.ink)
    }

    private func row(_ workout: LocalWorkoutTemplate, isNext: Bool) -> some View {
        let size = NextUp.sizeLine(exerciseCount: NextUp.strengthCount(workout), hasCardio: NextUp.hasCardio(workout))
        return HStack(spacing: EmberTokens.Spacing.space12) {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                Text(workout.name).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                Text(numerals: size).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
            }
            Spacer(minLength: EmberTokens.Spacing.space8)
            if isNext {
                Text("Next up").typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.ink)
                    .padding(.horizontal, EmberTokens.Spacing.space8)
                    .padding(.vertical, EmberTokens.Spacing.space4)
                    // A18.11 — a workout row inside a Button — picking one starts a session: a control boundary, so controlOutline and
                    // never the 1.26:1 hairline family, which is for the seam between two surfaces.
                    .overlay(Capsule().stroke(EmberColors.controlOutline, lineWidth: EmberTokens.Size.hairline))
            }
            Image(systemName: "chevron.right").foregroundStyle(EmberColors.chevron)
        }
        .padding(.vertical, EmberTokens.Spacing.space12)
        .frame(maxWidth: .infinity, minHeight: EmberTokens.Focus.rowButton, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(workout.name), \(size)\(isNext ? ", next up" : "")")
        .accessibilityHint("Starts a bonus workout")
    }
}
