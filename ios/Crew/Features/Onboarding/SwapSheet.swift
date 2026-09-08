// SPEC: Flow 1 step 4 — Tap → Swap → 3–5 alternatives that do the same job. Two taps. No questions asked, ever.
// Also used by the Plan editor (T014-S14) and mid-workout swaps (E7). WRITTEN — UNVERIFIED (needs Mac). T021

import SwiftUI

struct SwapSheet: View {
    let candidates: [SeedExercise]
    let onPick: (SeedExercise) -> Void

    var body: some View {
        NavigationStack {
            List(candidates) { candidate in
                Button { onPick(candidate) } label: {
                    VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                        HStack {
                            Text(candidate.name).font(.headline).foregroundStyle(EmberColors.inkText)
                            Spacer()
                            Text(candidate.equipment.capitalized).font(.caption).foregroundStyle(EmberColors.secondaryText)
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
            .navigationTitle("Swap")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
