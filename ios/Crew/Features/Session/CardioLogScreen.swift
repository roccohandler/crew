// SPEC: A2 (owner-directed 2026-09-08) — Log cardio from Home: an activity grid (nine tiles ≥ 44 pt, last-used first), a
// minutes stepper (cardioMinutesStep, bounds from the constants), an optional distance field with the unit suffix from the
// user's units ("Skip it if you don't know."), CTA "Log {activity}"; on success the normal celebration, then Home. A8:
// sentence case, verb-first. Part III law ①: every control is ink. Screens hold ZERO logic (5.6.6).
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct CardioLogScreen: View {
    let onLogged: (CelebrationOutcome) -> Void
    @State private var model = CardioLogModel()
    @FocusState private var distanceFocused: Bool // A19.2: the Done item needs something to clear

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Text("What did you do?").font(.headline).foregroundStyle(EmberColors.inkText)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: EmberTokens.Size.avatarLarge), spacing: EmberTokens.Spacing.space8)], spacing: EmberTokens.Spacing.space8) {
                    ForEach(model.activities) { activity in
                        ActivityTile(name: activity.name, selected: activity.id == model.activity?.id) {
                            Haptics.selection()
                            model.choose(activity)
                        }
                    }
                }
                Card {
                    VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                        SwiftUI.Stepper(value: $model.minutes, in: SpecConstants.cardioMinutesMin...SpecConstants.cardioMinutesMax, step: SpecConstants.cardioMinutesStep) { // the module's own Stepper (SetRow.swift) shadows SwiftUI's
                            Text("\(model.minutes) min").font(.title3.weight(.semibold).monospacedDigit()).foregroundStyle(EmberColors.inkText)
                        }
                        .tint(EmberColors.inkText)
                        .accessibilityLabel("Minutes")
                        .accessibilityValue("\(model.minutes)")
                        HStack(spacing: EmberTokens.Spacing.space8) {
                            TextField("Distance", text: $model.distanceText)
                                .keyboardType(.decimalPad)
                                .focused($distanceFocused)
                                .padding(EmberTokens.Spacing.space12)
                                .background(EmberColors.canvas, in: RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous))
                                .accessibilityLabel("Distance in \(model.unitSuffix)")
                            Text(model.unitSuffix).font(.body).foregroundStyle(EmberColors.secondaryText)
                        }
                        Text("Skip it if you don't know.").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                    }
                }
                if let error = model.submitError { Text(error).font(.footnote).foregroundStyle(EmberColors.danger) }
            }
            .padding(EmberTokens.Spacing.space16)
        }
        // SPEC: A19.1 / A19.2 — this screen was the worst of the dead ends. The primary sat below a `.decimalPad`
        // field, and a decimal pad ships NO RETURN KEY, so once the distance field had focus there was no way to
        // dismiss the keyboard and no way to reach the button underneath it: the only escape was the back gesture,
        // which throws the log away. The bar rises above the keyboard; the Done item below dismisses it.
        .crewBottomBar {
            PrimaryButton(title: model.activity.map { "Log \($0.name)" } ?? "Log cardio") { model.submit() }
                .disabled(!model.canSubmit)
                .opacity(model.canSubmit ? 1 : EmberTokens.Opacity.disabled)
        }
        // SPEC: A19.2 — `.decimalPad` and `.numberPad` carry no return key, and Apple's documented remedy is a
        // keyboard toolbar item. One Done, on the trailing side, dismissing the field that has focus.
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { distanceFocused = false }
            }
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle("Log cardio")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: model.outcome) { _, outcome in if let outcome { onLogged(outcome) } }
    }
}

// One activity tile: ink fill when chosen, card otherwise; the whole tile is the target (≥ 44 pt, 6.3)
struct ActivityTile: View {
    let name: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(selected ? EmberColors.primaryButtonLabel : EmberColors.inkText)
                .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.dayToggleMinPt))
                .background(selected ? EmberColors.primaryButtonFill : EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous))
                // A18.11 — the activity tiles: a control boundary, so controlOutline (3.32:1 on a card, 3.13:1 on the canvas) and never
                // the 1.26:1 hairline family, which is for the seam between two surfaces.
                .overlay(RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous).stroke(EmberColors.controlOutline, lineWidth: EmberTokens.Size.hairline))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
