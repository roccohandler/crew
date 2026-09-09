// SPEC: A4 (owner-directed 2026-09-08) — training days change without a rebuild: the seven ≥ dayToggleMinPt toggles from
// onboarding (1B / S03), the neutral whisper, `Save days`. The workouts and the rotation pointer are untouched (A1);
// forward-only. Screens hold zero logic (5.6.6): the model decides whether the days can be saved. Ink on bone.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct DaysSheet: View {
    let model: PlanModel
    let onSaved: () -> Void
    @State private var days: Set<Int>

    init(model: PlanModel, onSaved: @escaping () -> Void) {
        self.model = model
        self.onSaved = onSaved
        _days = State(initialValue: Set(model.plan?.trainingWeekdays ?? []))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space24) {
                Text("Which days do you train?").font(.title2.weight(.bold)).foregroundStyle(EmberColors.inkText)
                HStack(spacing: EmberTokens.Spacing.space4) {
                    ForEach(1...TimeUnits.daysPerWeek, id: \.self) { weekday in
                        DayToggle(letter: DayToggle.letters[weekday - 1], selected: days.contains(weekday)) {
                            Haptics.selection()
                            if days.contains(weekday) { days.remove(weekday) } else { days.insert(weekday) }
                        }
                    }
                }
                Text(DayToggle.whisper).font(.body).foregroundStyle(EmberColors.secondaryText)
                Text("Your workouts keep rotating; only the days change.").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                Spacer()
                if let line = model.errorLine { Text(line).font(.footnote).foregroundStyle(EmberColors.inkText) }
                PrimaryButton(title: "Save days") { if model.setTrainingWeekdays(days) { onSaved() } }
                    .disabled(!model.canSaveDays(days))
                    .opacity(model.canSaveDays(days) ? 1 : EmberTokens.Opacity.disabled)
            }
            .padding(EmberTokens.Spacing.space24)
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Change days")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(EmberColors.inkText)
        .presentationDetents([.medium, .large])
    }
}
