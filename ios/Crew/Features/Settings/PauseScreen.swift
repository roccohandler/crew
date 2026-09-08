// SPEC: Flow 7 planned absence — Settings → "Pause my plan" → pick return date (max 3 weeks) → streak freezes 🧊 · reminders stop ·
// crew dot shows ⏸ · no XP · one active pause · never retroactive · resumes automatically. S17. WRITTEN — UNVERIFIED. T041

import SwiftUI

struct PauseScreen: View {
    @Bindable var model: SettingsModel
    @State private var returnDate = Calendar.current.date(byAdding: .day, value: SpecConstants.pauseDefaultDays, to: Date()) ?? Date()
    @Environment(\.dismiss) private var dismiss

    private var range: ClosedRange<Date> {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        let latest = Calendar.current.date(byAdding: .day, value: SpecConstants.pauseMaxDays, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        return tomorrow...latest
    }

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            if let pause = model.pause {
                Text("Plan paused 🧊").font(.title2.weight(.bold)).foregroundStyle(EmberColors.inkText)
                Text("Streak frozen, reminders off, until \(pause.endDay).").font(.body).foregroundStyle(EmberColors.secondaryText)
                SecondaryButton(title: "End the pause now") { Task { await model.endPause(); dismiss() } }
            } else {
                Text("Pause my plan").font(.title2.weight(.bold)).foregroundStyle(EmberColors.inkText)
                Text("Vacations and injuries are life, not failure. Pick the day you're back — up to \(SpecConstants.pauseMaxDays) days out.").font(.body).foregroundStyle(EmberColors.secondaryText)
                DatePicker("Return date", selection: $returnDate, in: range, displayedComponents: .date).tint(EmberColors.inkText)
                if let error = model.errorLine { Text(error).font(.footnote).foregroundStyle(EmberColors.danger) }
                PrimaryButton(title: "Pause until then") {
                    Task { await model.pause(until: DayKey.localDateOf(returnDate, timeZone: .current)); if model.errorLine == nil { dismiss() } }
                }
            }
            Spacer()
        }
        .padding(EmberTokens.Spacing.space24)
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle("Pause")
        .task { await model.refresh() }
    }
}
