// SPEC: Flow 1 step 4 — Tap → Swap → 3–5 alternatives that do the same job. Two taps. No questions asked, ever.
// Also the Plan editor's picker (A4: `Swap`, `Add exercise`, `Add cardio` — same list, its own title) and the mid-workout
// swap (E7). WRITTEN — UNVERIFIED (needs Mac). T021

import SwiftUI

struct SwapSheet: View {
    var title = "Swap"
    let candidates: [SeedExercise]
    let onPick: (SeedExercise) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(candidates) { candidate in
                Button { onPick(candidate) } label: {
                    VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                        HStack {
                            Text(candidate.name).font(.headline).foregroundStyle(EmberColors.inkText)
                            Spacer()
                            EquipmentLabel(equipment: candidate.equipment) // A26
                        }
                        Text(candidate.cueLine).font(.subheadline).foregroundStyle(EmberColors.secondaryText)
                    }
                    .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                }
                .buttonStyle(.plain)
                .listRowBackground(EmberColors.card)
            }
            .scrollContentBackground(.hidden)
            .background(EmberColors.canvas)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            // SPEC: 6.3 · 6.7 (DESIGN.md 4.2) — every swipe has a visible-button equivalent. The sheet could only be pulled down
            // (ui-reviewer, run 35405384572), and a slip on the reveal opens it from any row; the other sheets already say Cancel.
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}
