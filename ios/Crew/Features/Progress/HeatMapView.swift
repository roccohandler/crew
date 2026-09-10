// SPEC: Flow 9 layer 1 — the heat map; tap a day → that day's workout + plates; ember fills = progress (Part III law ④); a missed
// day is neutral, never red. A6 (owner-directed 2026-09-08): VoiceOver reads the DayLabel ("Yesterday", "Mon Sep 1"), never a
// raw ISO date. WRITTEN — UNVERIFIED (needs Mac). T040

import SwiftUI

struct HeatMapView: View {
    let days: [DayCell]
    let todayKey: String
    let selected: String?
    let onSelect: (String) -> Void
    private let columns = Array(repeating: GridItem(.flexible(), spacing: EmberTokens.Spacing.space4), count: TimeUnits.daysPerWeek)

    var body: some View {
        LazyVGrid(columns: columns, spacing: EmberTokens.Spacing.space4) {
            ForEach(days) { day in
                Button { onSelect(day.dayKey) } label: {
                    // A14: three marks in ONE hue — a workout is a solid ember cell, a cardio day the same ember as an
                    // outline, a posted-only day the ember tint. Fill treatment is the third channel, so law ⑥ gains no
                    // second colour and the marks stay distinguishable in grayscale.
                    RoundedRectangle(cornerRadius: EmberTokens.Spacing.space4, style: .continuous)
                        .fill(day.workout ? EmberColors.ember : (day.posted ? EmberColors.emberTint : EmberColors.hairline))
                        .overlay(RoundedRectangle(cornerRadius: EmberTokens.Spacing.space4, style: .continuous).stroke(EmberColors.ember, lineWidth: day.cardio && !day.workout ? EmberTokens.Size.hairline + EmberTokens.Size.hairline : 0))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(RoundedRectangle(cornerRadius: EmberTokens.Spacing.space4, style: .continuous).stroke(EmberColors.inkText, lineWidth: selected == day.dayKey ? EmberTokens.Size.hairline + EmberTokens.Size.hairline : 0))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(DayLabel.dayLabel(day.dayKey, todayKey: todayKey))\(day.workout ? ", workout" : (day.cardio ? ", cardio" : (day.posted ? ", posted" : "")))")
            }
        }
    }
}
