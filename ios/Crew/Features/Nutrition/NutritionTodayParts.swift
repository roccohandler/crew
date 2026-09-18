// SPEC: nutrition addendum §4 (Today) — the three blocks under the macro lines. "Your template": one row per slot, ONE tap logs it
// (✓), the same tap undoes it in place, and a skipped slot is simply unlogged — a checklist, never a requirement. "Quick add": three
// gram steppers and Add (an OUTLINE button: Today carries no ink-filled primary of its own, Q3). Then today's log, every row with
// its visible Delete (6.3: a swipe is never the only way). The empty state is the template INVITATION. Ink only: no macro fill, no
// ember, no semantic colour (law ⑥'s exception). Every string comes from the MacroDay twin.
// Twin of web components/nutrition/TodayParts.tsx. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct TemplateRows: View {
    let slots: [SlotLine]
    let onTap: (SlotLine) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.rowGap) {
            Text("Your template").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText).accessibilityAddTraits(.isHeader)
            if slots.isEmpty {
                Text("Build your usual day once. After that, one tap logs a meal.").font(.body).foregroundStyle(EmberColors.secondaryText)
            } else {
                VStack(spacing: 0) {
                    ForEach(slots) { slot in
                        if slot.id > 0 { Rectangle().fill(EmberColors.hairline).frame(height: EmberTokens.Size.hairline) }
                        TemplateSlotRow(slot: slot) { onTap(slot) }
                    }
                }
                // One boundary around the group (A18.11: controlOutline on a control, the hairline only between two surfaces)
                .overlay(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous).stroke(EmberColors.controlOutline, lineWidth: EmberTokens.Size.hairline))
                .clipShape(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous))
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
                Image(systemName: slot.tickedLogId == nil ? "circle" : "checkmark.circle.fill").foregroundStyle(EmberColors.inkText)
                Text(slot.title).font(.body.weight(.semibold)).foregroundStyle(EmberColors.inkText).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: EmberTokens.Spacing.space8)
                Text(MacroDay.gramsText(slot.meal.grams)).font(.subheadline.monospacedDigit()).foregroundStyle(EmberColors.inkText).lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: minTarget, alignment: .leading)
            .padding(.horizontal, EmberTokens.Spacing.space16)
            .padding(.vertical, EmberTokens.Spacing.space12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(slot.title), \(MacroDay.gramsSpoken(slot.meal.grams)), \(slot.tickedLogId == nil ? "not logged" : "logged, tap to undo")")
        .accessibilityAddTraits(slot.tickedLogId == nil ? [] : .isSelected)
    }
}

struct QuickAddBlock: View {
    var focus: FocusState<String?>.Binding
    let onAdd: (MacroGrams) -> Void
    @State private var grams = MacroGrams(proteinG: 0, carbsG: 0, fatG: 0)

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.rowGap) {
            Text("Quick add").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText).accessibilityAddTraits(.isHeader)
            GramFields(grams: $grams, limit: SpecConstants.macroGramsMaxPerEntry, focus: focus, prefix: "quick")
            SecondaryButton(title: "Add") {
                focus.wrappedValue = nil
                onAdd(grams)
                grams = MacroGrams(proteinG: 0, carbsG: 0, fatG: 0)
            }
            .disabled(isEmpty)
            .opacity(isEmpty ? EmberTokens.Opacity.disabled : 1)
        }
    }

    private var isEmpty: Bool { grams.proteinG + grams.carbsG + grams.fatG == 0 }
}

struct LogList: View {
    let logs: [MealLine]
    let onDelete: (MealLine) -> Void

    var body: some View {
        if !logs.isEmpty {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.rowGap) {
                Text("Logged today").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText).accessibilityAddTraits(.isHeader)
                ForEach(logs) { log in MealLineRow(line: log, actions: [MealLineAction(title: "Delete", spoken: "Delete \(log.name)") { onDelete(log) }]) }
            }
        }
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
                Text(title ?? line.name).font(.body).foregroundStyle(EmberColors.inkText).fixedSize(horizontal: false, vertical: true)
                Text(MacroDay.gramsText(line.grams)).font(.subheadline.monospacedDigit()).foregroundStyle(EmberColors.secondaryText).lineLimit(1)
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
