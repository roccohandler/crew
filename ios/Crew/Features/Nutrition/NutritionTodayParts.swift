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
                            if slot.id > 0 { cardSeam() }
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

    @ScaledMetric private var circle: CGFloat = EmberTokens.Focus.checkCircle
    @ScaledMetric private var glyph: CGFloat = EmberTokens.Focus.checkGlyph

    var body: some View {
        Button(action: action) {
            HStack(spacing: EmberTokens.Spacing.space12) {
                // The tick is the kit's check (system §8: a 28 pt circle, a 2 pt ink ring when open, solid ink with an onInk tick when
                // done — R-093; the SF circle was ~17 pt) — a SHAPE in ink, state is never colour (§7.4 encoder ⑤)
                ZStack {
                    if slot.tickedLogId == nil {
                        Circle().strokeBorder(EmberColors.ink, lineWidth: EmberTokens.Focus.checkRing)
                    } else {
                        Circle().fill(EmberColors.ink)
                        Image(systemName: "checkmark").font(.system(size: glyph, weight: .bold)).foregroundStyle(EmberColors.onInk)
                    }
                }
                .frame(width: circle, height: circle)
                // the words over their grams, so a long slot name no longer wraps against the numbers
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                    Text(slot.title).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                    Text(numerals: MacroDay.gramsText(slot.meal.grams)).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary).lineLimit(1)
                }
                Spacer(minLength: 0)
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
// as the kit's text buttons (15 pt Semibold ink — R-093). A row of a card: it carries the card's inset.
struct MealLineRow: View {
    let line: MealLine
    var title: String? = nil
    let actions: [MealLineAction]

    var body: some View {
        // the words keep the row's width when the actions would squeeze them (the template's Up · Down · Remove): the actions drop
        // to a line of their own under the grams instead
        ViewThatFits(in: .horizontal) {
            HStack(spacing: EmberTokens.Spacing.space12) {
                words(fixed: true)
                Spacer(minLength: EmberTokens.Spacing.space4)
                buttons
            }
            VStack(alignment: .leading, spacing: 0) {
                words(fixed: false)
                HStack(spacing: EmberTokens.Spacing.space16) { buttons }
            }
        }
        .padding(.horizontal, EmberTokens.Focus.setCardInset)
        .padding(.vertical, EmberTokens.Spacing.space8)
    }

    // fixed: the one-line test ViewThatFits measures; otherwise the name wraps (6.7: nothing truncates)
    private func words(fixed: Bool) -> some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
            Text(title ?? line.name).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink).fixedSize(horizontal: fixed, vertical: true)
            Text(numerals: MacroDay.gramsText(line.grams)).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary).lineLimit(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title ?? line.name), \(MacroDay.gramsSpoken(line.grams))")
    }

    private var buttons: some View {
        ForEach(actions) { action in
            TextActionButton(title: action.title, horizontalPadding: 0, accessibilityLabel: action.spoken, role: EmberTokens.Typography.textButton, action: action.run)
        }
    }
}
