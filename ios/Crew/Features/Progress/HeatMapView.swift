// SPEC: Flow 9 layer 1 as amended by A28 (b), (d), (f) (owner-approved 2026-09-19; design/targets 12) — the heat map (system §8): a
// 7-column grid under the weekday letters, one row per week, 7 pt gaps, radius 8. TWO states: a day holding a completed workout is
// INK, every other day heatEmpty — no accent anywhere on Progress (A28 (b)), and heatEmpty (~1.2:1) is never a state's only carrier
// (R-083 (25)): each cell's VoiceOver label says what the day held, a standalone cardio log and a post included (A14 keeps both
// facts; the map draws only the workout — R-086). Tap a day → that day's workouts; days before the season and this week's days to
// come draw empty and answer no tap (R-091 (5)). §10:
// the grid keeps seven columns at every size and lets the cells shrink. A6: VoiceOver reads the DayLabel, never raw ISO.
// WRITTEN — UNVERIFIED (needs Mac). T040 · R3

import SwiftUI

struct HeatMapView: View {
    let days: [DayCell]
    let todayKey: String
    let selected: String?
    let onSelect: (String) -> Void
    private let columns = Array(repeating: GridItem(.flexible(), spacing: EmberTokens.Focus.heatGap), count: TimeUnits.daysPerWeek)
    private let letters = ["M", "T", "W", "T", "F", "S", "S"] // ISO order, Monday first (E20)

    var body: some View {
        LazyVGrid(columns: columns, spacing: EmberTokens.Focus.heatGap) {
            ForEach(Array(letters.enumerated()), id: \.offset) { _, letter in
                Text(letter).typeRole(EmberTokens.Typography.eyebrowWeekday).foregroundStyle(EmberColors.inkSecondary)
                    .accessibilityHidden(true)
            }
            ForEach(days) { day in
                if day.outside {
                    cell(day).accessibilityHidden(true)
                } else {
                    Button { onSelect(day.dayKey) } label: { cell(day) }
                        .buttonStyle(.plain)
                        .accessibilityLabel(label(day))
                        .accessibilityAddTraits(selected == day.dayKey ? .isSelected : [])
                }
            }
        }
    }

    private func cell(_ day: DayCell) -> some View {
        let shape = RoundedRectangle(cornerRadius: EmberTokens.Focus.heatRadius, style: .continuous)
        return shape
            .fill(day.workout ? EmberColors.ink : EmberColors.heatEmpty)
            .frame(height: EmberTokens.Focus.heatCell) // system §8: 30 pt tall; the width is the column's, so seven always fit (§10)
            // the tapped day: an ink ring just outside the cell, in the gap, so it reads on an ink cell and an empty one alike
            .overlay(shape.inset(by: -EmberTokens.Focus.checkRing - EmberTokens.Focus.checkRing).strokeBorder(EmberColors.ink, lineWidth: selected == day.dayKey ? EmberTokens.Focus.checkRing : 0))
    }

    private func label(_ day: DayCell) -> String {
        let held = day.workout ? ", workout" : (day.cardio ? ", cardio" : (day.posted ? ", posted" : ""))
        return "\(DayLabel.dayLabel(day.dayKey, todayKey: todayKey))\(held)"
    }
}
