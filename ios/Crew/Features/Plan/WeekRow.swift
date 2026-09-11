// SPEC: A4 (owner-directed 2026-09-08) · A1 · S14 — one row of the week map: `Mon · Push day` / `5 exercises + mobility`
// with a chevron; done days `Mon · ✓ Push day`; open past days `Mon · —` in secondary ink, no word (A8: never a verdict);
// rest days `Tue · Rest`. The whole row is the one tap target (≥ dayToggleMinPt tall, 6.3); the map holds zero controls.
// WeekMapRow.make is the plain function PlanModel and OnboardingModel build their rows with, so the screens hold zero
// logic (5.6.6). Ink on bone only, never orange. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct WeekMapRow: Equatable, Identifiable {
    let weekday: Int
    let title: String
    let detail: String?
    let kind: String?      // the workout the row opens; nil on rest and open days
    let quiet: Bool        // secondary ink: rest and open days
    var id: Int { weekday }

    // SPEC: A1 · A4 — the projection's four states in words; the name comes from the plan's workout, never from its kind
    @MainActor
    static func make(_ day: DayProjection, workouts: [PlanDraftWorkout]) -> WeekMapRow {
        let dayName = DayLabel.weekdayNames[day.weekday - 1]
        let workout = workouts.first { $0.kind == day.kind }
        let name = workout?.name ?? day.kind ?? ""
        let size = workout.map { NextUp.sizeLine(exerciseCount: $0.exercises.filter { $0.type == "strength" }.count, hasCardio: $0.exercises.contains { $0.type == "cardio" }) }
        switch day.state {
        case .rest: return WeekMapRow(weekday: day.weekday, title: "\(dayName) · Rest", detail: nil, kind: nil, quiet: true)
        case .open: return WeekMapRow(weekday: day.weekday, title: "\(dayName) · —", detail: nil, kind: nil, quiet: true)
        case .done: return WeekMapRow(weekday: day.weekday, title: "\(dayName) · ✓ \(name)", detail: size, kind: day.kind, quiet: false)
        case .planned: return WeekMapRow(weekday: day.weekday, title: "\(dayName) · \(name)", detail: size, kind: day.kind, quiet: false)
        }
    }
}

struct WeekRow: View {
    let row: WeekMapRow
    var interactive = true
    let onTap: () -> Void

    private var opensWorkout: Bool { interactive && row.kind != nil }

    var body: some View {
        if opensWorkout {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
                .accessibilityLabel(label)
                .accessibilityHint("Opens the workout")
        } else {
            content.accessibilityElement(children: .combine).accessibilityLabel(label)
        }
    }

    private var label: String { row.detail.map { "\(row.title). \($0)" } ?? row.title }

    private var content: some View {
        HStack(spacing: EmberTokens.Spacing.space12) {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                Text(row.title).font(.headline).foregroundStyle(row.quiet ? EmberColors.secondaryText : EmberColors.inkText)
                if let detail = row.detail { Text(detail).font(.subheadline).foregroundStyle(EmberColors.secondaryText) }
            }
            Spacer()
            if opensWorkout { Image(systemName: "chevron.right").font(.subheadline.weight(.semibold)).foregroundStyle(EmberColors.secondaryText) }
        }
        .padding(.horizontal, EmberTokens.Spacing.space16)
        .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.dayToggleMinPt), alignment: .leading)
        .background(EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous))
        // A18.11 — the row is a CONTROL when it opens a workout and a read-only surface when it does not (the
        // generated-plan preview passes `interactive: false`), and `opensWorkout` already draws that line for the
        // Button, the chevron and the a11y hint. The boundary follows it: controlOutline at 3.32:1 where a finger
        // acts, hairline where it is only a card edge.
        .overlay(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous).stroke(opensWorkout ? EmberColors.controlOutline : EmberColors.hairline, lineWidth: EmberTokens.Size.hairline))
        .contentShape(Rectangle())
    }
}
