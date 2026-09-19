// SPEC: Flow 7 planned absence — Settings → "Pause my plan" → pick return date (max 3 weeks) → streak freezes 🧊 · reminders stop ·
// crew dot shows ⏸ · no XP · one active pause · never retroactive · resumes automatically. S17. R-092: one title (the heading), and
// the line under it states instead of instructing (A28 (e)); Flow 7's own sentence stays. WRITTEN — UNVERIFIED. T041

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
                // A28 (e) — the off-season in the settled words (Home says the same, mockup 06), no emoji (R-083 (12))
                Text("Off-season").typeRole(EmberTokens.Typography.screenTitle).foregroundStyle(EmberColors.ink)
                Text("Off-season until \(model.pauseUntilLabel ?? pause.endDay). Reminders are off.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.inkSecondary) // A3/A6: a day label, never raw ISO
                Spacer(minLength: 0)
                PrimaryButton(title: "End the pause") { Task { await model.endPause(); dismiss() } } // the one filled button, as on Home
            } else {
                Text("Pause my plan").typeRole(EmberTokens.Typography.screenTitle).foregroundStyle(EmberColors.ink)
                Text(numerals: "Vacations and injuries are life, not failure. Your plan picks up again on the day you choose, up to \(SpecConstants.pauseMaxDays) days out.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.inkSecondary)
                DatePicker("Return date", selection: $returnDate, in: range, displayedComponents: .date).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink).tint(EmberColors.ink)
                if let error = model.errorLine { Text(error).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink) } // A28 (a): red only in a destructive confirm
                Spacer(minLength: 0)
                PrimaryButton(title: "Pause until then") {
                    Task { await model.pause(until: DayKey.localDateOf(returnDate, timeZone: .current)); if model.errorLine == nil { dismiss() } }
                }
            }
        }
        .padding(.horizontal, EmberTokens.Focus.gutter)
        .padding(.vertical, EmberTokens.Spacing.space24)
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline) // R-092: the page's heading is its title — a bar title over it named the page twice
        .task { await model.refresh() }
    }
}
