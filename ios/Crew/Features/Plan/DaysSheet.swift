// SPEC: A4 (owner-directed 2026-09-08) as amended by A27 (a) and A28 (f) — training days change without a rebuild: the system's
// sheet (on `card`, 28 pt top corners, the grabber), the seven ≥ dayToggleMinPt toggles from onboarding (1B / S03), the neutral
// whisper, and `Save days`, its one filled button. A27 (a): training days are a standing setting, and this screen states the
// forward-only rule in ONE line (R-087: "Changes apply from your next workout on. Days already past keep the plan they had.").
// The workouts and the rotation pointer are untouched (A1). Screens hold zero logic (5.6.6): the model decides whether the days
// can be saved. WRITTEN — UNVERIFIED (needs Mac). R4

import SwiftUI

struct DaysSheet: View {
    let model: PlanModel
    let onSaved: () -> Void
    @State private var days: Set<Int>
    @Environment(\.dismiss) private var dismiss

    init(model: PlanModel, onSaved: @escaping () -> Void) {
        self.model = model
        self.onSaved = onSaved
        _days = State(initialValue: Set(model.plan?.trainingWeekdays ?? []))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space24) {
            Text("Which days do you train?").typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: EmberTokens.Spacing.space4) {
                ForEach(1...TimeUnits.daysPerWeek, id: \.self) { weekday in
                    DayToggle(letter: DayToggle.letters[weekday - 1], selected: days.contains(weekday)) {
                        Haptics.selection()
                        if days.contains(weekday) { days.remove(weekday) } else { days.insert(weekday) }
                    }
                }
            }
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                Text(numerals: DayToggle.whisper).typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.ink)
                // SPEC: A27 (a) — the forward-only rule, in one line
                Text("Changes apply from your next workout on. Days already past keep the plan they had.")
                    .typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if let line = model.errorLine { Text(line).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink) }
            PrimaryButton(title: "Save days") { if model.setTrainingWeekdays(days) { onSaved() } }
                .disabled(!model.canSaveDays(days))
            TextActionButton(title: "Cancel", role: EmberTokens.Typography.textButton) { dismiss() } // 6.3: the pull has a visible twin
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, EmberTokens.Focus.gutter)
        .padding(.top, EmberTokens.Spacing.space32)
        .padding(.bottom, EmberTokens.Spacing.space12)
        .background(EmberColors.card.ignoresSafeArea())
        .tint(EmberColors.ink)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(EmberTokens.Focus.cardRadius)
    }
}
