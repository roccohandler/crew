// SPEC: A28 (d), (f) (owner-approved 2026-09-19; design/targets 07, 08) — the set screen's ONE card of two metric rows. Each BIG
// NUMERAL is a value button that opens the keypad (§8: no box, no underline, no field chrome — the number is the control), the
// unit is a word beside it (A28 (d): lb/kg lives in Settings; the session never asks), and the − / + steppers sit on the right.
// §10: where the row does not fit (accessibility sizes, a five-figure weight) it breaks to numeral over steppers; nothing
// truncates. Replaces A10's weight tape (a ruler — system §11) and the set rows (A21.11's compact rows). WRITTEN — UNVERIFIED.

import SwiftUI

struct SetCard<First: View, Second: View>: View {
    @ViewBuilder let first: () -> First
    @ViewBuilder let second: () -> Second

    var body: some View {
        FocusCard(padding: 0) {
            VStack(spacing: 0) {
                first().padding(.horizontal, EmberTokens.Focus.setCardInset).padding(.vertical, EmberTokens.Focus.setRowPadding)
                second()
            }
        }
    }
}

// The seam between the card's two rows, inset like the rows it separates; a bodyweight exercise has one row and no seam
struct SetCardSecondRow<Row: View>: View {
    @ViewBuilder let row: () -> Row

    var body: some View {
        Rectangle().fill(EmberColors.hairlineOnCard).frame(height: EmberTokens.Size.hairline).padding(.horizontal, EmberTokens.Focus.setCardInset)
        row().padding(.horizontal, EmberTokens.Focus.setCardInset).padding(.vertical, EmberTokens.Focus.setRowPadding)
    }
}

struct MetricRow: View {
    let value: String     // "8" · "150" · "—"
    let unit: String      // "reps" · "lb" · "min" · "km"
    let noun: String      // what VoiceOver says the steppers change: "reps", "weight", "minutes"
    let onType: () -> Void
    var onStep: ((Int) -> Void)? = nil

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: EmberTokens.Spacing.space12) {
                valueButton
                Spacer(minLength: EmberTokens.Spacing.space8)
                steppers
            }
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                valueButton
                steppers
            }
        }
    }

    private var valueButton: some View {
        Button(action: onType) {
            HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Focus.space6) {
                Text(value).typeRole(EmberTokens.Typography.heroNumeral).foregroundStyle(EmberColors.ink)
                    .fixedSize()
                    .contentTransition(.numericText())
                Text(unit).typeRole(EmberTokens.Typography.heroUnit).foregroundStyle(EmberColors.inkSecondary)
                    .fixedSize()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(value == "—" ? "No" : value) \(unit)")
        .accessibilityHint("Double-tap to type a number")
        // 6.5 — swipe up / down changes the value by one step, like a native stepper
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onStep?(1)
            case .decrement: onStep?(-1)
            @unknown default: break
            }
        }
    }

    @ViewBuilder
    private var steppers: some View {
        if let onStep {
            HStack(spacing: EmberTokens.Spacing.space12) {
                StepButton(symbol: "minus", noun: noun, focus: true) { onStep(-1) }
                StepButton(symbol: "plus", noun: noun, focus: true) { onStep(1) }
            }
        }
    }
}
