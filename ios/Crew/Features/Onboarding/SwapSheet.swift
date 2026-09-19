// SPEC: Flow 1 step 4 — Tap → Swap → 3–5 alternatives that do the same job. Two taps. No questions asked, ever.
// Also the Plan editor's picker (A4: `Swap`, `Add exercise`, `Add cardio` — same list, its own title) and the mid-workout
// swap (E7). A28 (f) · R4: the system's sheet — `card`, 28 pt top corners, the grabber, the title in the content at `sheetTitle`
// with Cancel beside it (a navigation bar's small centred title is not the system's sheet, ui-reviewer run 35444308817), and the
// alternatives as plain rows on the gutter. WRITTEN — UNVERIFIED (needs Mac). T021
import SwiftUI

struct SwapSheet: View {
    var title = "Swap"
    let candidates: [SeedExercise]
    let onPick: (SeedExercise) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space12) {
                    Text(title).typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: EmberTokens.Spacing.space8)
                    // SPEC: 6.3 · 6.7 (DESIGN.md 4.2) — every swipe has a visible-button equivalent (ui-reviewer, run 35405384572)
                    TextActionButton(title: "Cancel", role: EmberTokens.Typography.textButton) { dismiss() }
                }
                VStack(spacing: 0) {
                    ForEach(Array(candidates.enumerated()), id: \.element.id) { index, candidate in
                        if index > 0 { Rectangle().fill(EmberColors.hairlineOnCard).frame(height: EmberTokens.Size.hairline) }
                        row(candidate)
                    }
                }
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.top, EmberTokens.Spacing.space32)
            .padding(.bottom, EmberTokens.Spacing.space24)
        }
        .background(EmberColors.card.ignoresSafeArea()) // A28 (f): the sheet surface is `card`
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(EmberTokens.Focus.cardRadius)
        .tint(EmberColors.ink)
    }

    private func row(_ candidate: SeedExercise) -> some View {
        Button { onPick(candidate) } label: {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(candidate.name).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: EmberTokens.Spacing.space8)
                    EquipmentLabel(equipment: candidate.equipment) // A26
                }
                Text(candidate.cueLine).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, EmberTokens.Spacing.space12)
            .frame(maxWidth: .infinity, minHeight: EmberTokens.Focus.rowButton, alignment: .leading) // A28 (f): a row button, 56 pt minimum
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
