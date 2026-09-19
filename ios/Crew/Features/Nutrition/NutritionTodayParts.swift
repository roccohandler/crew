// SPEC: nutrition addendum §4 (Today) · 6.9 Screen Density (A25) — "Your template" IS Today's job: one row per slot, ONE tap logs it
// (✓), the same tap undoes it in place, and a skipped slot is simply unlogged — a checklist, never a requirement. The empty state is
// the template INVITATION. Quick add and today's log are destinations of their own (QuickAddScreen.swift; R-077). Below: the one row
// every nutrition list shares — a meal, a slot or a log with its own VISIBLE actions (6.3: a swipe is never the only way). Ink only:
// no macro fill, no ember, no semantic colour (law ⑥'s exception). Every string comes from the MacroDay twin.
// Twin of web components/nutrition/TodayParts.tsx. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct TemplateRows: View {
    let slots: [SlotLine]
    let onTap: (SlotLine) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.rowGap) {
            Text("Your template").typeRole(EmberTokens.Typography.cardSubheading).foregroundStyle(EmberColors.ink).accessibilityAddTraits(.isHeader)
            if slots.isEmpty {
                Text("Build your usual day once. After that, one tap logs a meal.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.inkSecondary)
            } else {
                // A28 (f) · R7: the group is the system's card, its slots row buttons with the seam between them
                FocusCard(padding: 0) {
                    VStack(spacing: 0) {
                        ForEach(slots) { slot in
                            if slot.id > 0 { Rectangle().fill(EmberColors.hairlineOnCard).frame(height: EmberTokens.Size.hairline).padding(.leading, EmberTokens.Focus.setCardInset) }
                            TemplateSlotRow(slot: slot) { onTap(slot) }
                        }
                    }
                }
                Whisper(.howShake) // A23: the first template slot
            }
        }
    }
}

struct TemplateSlotRow: View {
    let slot: SlotLine
    let action: () -> Void
    @ScaledMetric private var minTarget: CGFloat = CGFloat(SpecConstants.minTouchTargetPt)

    var body: some View {
        Button(action: action) {
            HStack(spacing: EmberTokens.Spacing.space8) {
                // The tick is a SHAPE in ink — state is never colour (§7.4 encoder ⑤)
                Image(systemName: slot.tickedLogId == nil ? "circle" : "checkmark.circle.fill").foregroundStyle(EmberColors.ink)
                Text(slot.title).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: EmberTokens.Spacing.space8)
                Text(numerals: MacroDay.gramsText(slot.meal.grams)).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink).lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: minTarget, alignment: .leading)
            .padding(.horizontal, EmberTokens.Focus.setCardInset)
            .padding(.vertical, EmberTokens.Spacing.space12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(slot.title), \(MacroDay.gramsSpoken(slot.meal.grams)), \(slot.tickedLogId == nil ? "not logged" : "logged, tap to undo")")
        .accessibilityAddTraits(slot.tickedLogId == nil ? [] : .isSelected)
    }
}

struct MealLineAction: Identifiable {
    let title: String
    let spoken: String
    let run: () -> Void
    var id: String { title }
}

// A meal, a slot or a log with its own visible actions: the words first, the three numbers never broken apart, the actions trailing
struct MealLineRow: View {
    let line: MealLine
    var title: String? = nil
    let actions: [MealLineAction]

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space4) {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                Text(title ?? line.name).typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.ink).fixedSize(horizontal: false, vertical: true)
                Text(numerals: MacroDay.gramsText(line.grams)).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary).lineLimit(1)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(title ?? line.name), \(MacroDay.gramsSpoken(line.grams))")
            Spacer(minLength: EmberTokens.Spacing.space4)
            ForEach(actions) { action in
                TextActionButton(title: action.title, horizontalPadding: EmberTokens.Spacing.space8, accessibilityLabel: action.spoken, action: action.run)
            }
        }
    }
}
