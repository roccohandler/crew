// SPEC: A3 (owner-directed 2026-09-08) — Bonus workout: a sheet listing the plan's workouts, the next rotation workout first
// and labelled "Next up"; starting one creates a session with isPlannedDay false on a rest or done day (+25, V30/V31 — never
// expected, Flow 5). A8: no XP promise in the CTA, orange only on rewards. Part III law ①: every row is ink. Branches only on
// view state (5.6.6); the order comes from HomeModel.bonusWorkouts. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct BonusWorkoutSheet: View {
    let workouts: [LocalWorkoutTemplate]   // next up first
    let onPick: (LocalWorkoutTemplate) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Array(workouts.enumerated()), id: \.element.kind) { index, workout in
                        Button { onPick(workout) } label: { row(workout, isNext: index == 0) }
                            .buttonStyle(.plain)
                            .listRowBackground(EmberColors.card)
                    }
                } footer: {
                    Text("Never expected. Pick whatever you feel like.").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                }
            }
            .scrollContentBackground(.hidden)
            .background(EmberColors.canvas)
            .navigationTitle("Bonus workout")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private func row(_ workout: LocalWorkoutTemplate, isNext: Bool) -> some View {
        let size = NextUp.sizeLine(exerciseCount: NextUp.strengthCount(workout), hasCardio: NextUp.hasCardio(workout))
        return HStack(spacing: EmberTokens.Spacing.space12) {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                Text(workout.name).font(.headline).foregroundStyle(EmberColors.inkText)
                Text(size).font(.subheadline).foregroundStyle(EmberColors.secondaryText)
            }
            Spacer()
            if isNext {
                Text("Next up")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(EmberColors.inkText)
                    .padding(.horizontal, EmberTokens.Spacing.space8)
                    .padding(.vertical, EmberTokens.Spacing.space4)
                    // A18.11 — a workout row inside a Button — picking one starts a session: a control boundary, so controlOutline (3.32:1 on a card, 3.13:1 on the canvas) and never
                    // the 1.26:1 hairline family, which is for the seam between two surfaces.
                    .overlay(Capsule().stroke(EmberColors.controlOutline, lineWidth: EmberTokens.Size.hairline))
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(EmberColors.secondaryText)
        }
        .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(workout.name), \(size)\(isNext ? ", next up" : "")")
        .accessibilityHint("Starts a bonus workout")
    }
}
