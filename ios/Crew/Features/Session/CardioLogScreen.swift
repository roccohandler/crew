// SPEC: A2 (owner-directed 2026-09-08) — Log cardio from Home: an activity grid (nine tiles ≥ 44 pt, last-used first), the minutes
// (cardioMinutesStep, bounds from the constants), an optional distance in the user's unit, CTA "Log {activity}"; on success the
// normal celebration, then Home. A28 (d), (f) — drawn as the Logger draws a cardio block (R-084 (2)): ONE card of two metric rows,
// the minutes with the 52 pt steppers and the distance, each numeral a value button that opens the keypad (no field chrome, no
// grey placeholder, no UIKit stepper — ui-reviewer, run 35444308817). A28 (e): the distance line states, it does not instruct.
// A8: sentence case, verb-first. Part III law ①: every control is ink. Screens hold ZERO logic (5.6.6). WRITTEN — UNVERIFIED.

import SwiftUI

struct CardioLogScreen: View {
    let onLogged: (CelebrationOutcome) -> Void
    @State private var model = CardioLogModel()
    @State private var typing: TypedField?
    @State private var typed = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Text("What did you do?").typeRole(EmberTokens.Typography.cardSubheading).foregroundStyle(EmberColors.ink)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: EmberTokens.Size.avatarLarge), spacing: EmberTokens.Spacing.space8)], spacing: EmberTokens.Spacing.space8) {
                    ForEach(model.activities) { activity in
                        ActivityTile(name: activity.name, selected: activity.id == model.activity?.id) {
                            Haptics.selection()
                            model.choose(activity)
                        }
                    }
                }
                .padding(.bottom, EmberTokens.Spacing.space8)
                SetCard {
                    MetricRow(value: "\(model.minutes)", unit: "min", noun: "minutes", onType: { begin(.minutes, "\(model.minutes)") }) { model.stepMinutes(by: $0) }
                } second: {
                    SetCardSecondRow { MetricRow(value: model.distanceValue, unit: model.unitSuffix, noun: "distance", onType: { begin(.distance, model.distanceText) }) }
                }
                Text("Distance is optional.").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                if let error = model.submitError { Text(error).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink) }
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.vertical, EmberTokens.Spacing.space16)
        }
        // SPEC: A19.1 — the primary sits in a bar that rises above the keyboard; the keypad is an alert with its own buttons, so the
        // decimal pad's missing return key (A19.2) can no longer strand the user under it
        .crewBottomBar {
            PrimaryButton(title: model.activity.map { "Log \($0.name)" } ?? "Log cardio") { model.submit() }
                .disabled(!model.canSubmit)
        }
        .alert(typing?.title(units: model.unitSuffix, distanceUnit: model.unitSuffix) ?? "", isPresented: Binding(get: { typing != nil }, set: { if !$0 { typing = nil } })) {
            TextField(typing?.title(units: model.unitSuffix, distanceUnit: model.unitSuffix) ?? "", text: $typed).keyboardType(typing == .minutes ? .numberPad : .decimalPad)
            Button("Set") { commitTyped() }
            Button("Cancel", role: .cancel) { typed = "" }
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle("Log cardio")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: model.outcome) { _, outcome in if let outcome { onLogged(outcome) } }
    }

    private func begin(_ field: TypedField, _ current: String) {
        typed = current
        typing = field
    }

    // SPEC: A2 — a typed number is clamped by the model; an empty distance clears it (it is optional)
    private func commitTyped() {
        defer { typed = "" }
        if typing == .minutes, let value = Int(typed) { model.setMinutes(value) }
        if typing == .distance { model.distanceText = typed }
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
                .typeRole(EmberTokens.Typography.textButton)
                .multilineTextAlignment(.center)
                .foregroundStyle(selected ? EmberColors.onInk : EmberColors.ink)
                .padding(.horizontal, EmberTokens.Spacing.space4)
                .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.dayToggleMinPt))
                .background(selected ? EmberColors.ink : EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous))
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
