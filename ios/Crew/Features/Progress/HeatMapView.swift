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
                    RoundedRectangle(cornerRadius: EmberTokens.Spacing.space4, style: .continuous)
                        .fill(day.workout ? EmberColors.ember : (day.posted ? EmberColors.emberTint : EmberColors.hairline))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(RoundedRectangle(cornerRadius: EmberTokens.Spacing.space4, style: .continuous).stroke(EmberColors.inkText, lineWidth: selected == day.dayKey ? EmberTokens.Size.hairline + EmberTokens.Size.hairline : 0))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(DayLabel.dayLabel(day.dayKey, todayKey: todayKey))\(day.workout ? ", workout" : (day.posted ? ", posted" : ""))")
            }
        }
    }
}
