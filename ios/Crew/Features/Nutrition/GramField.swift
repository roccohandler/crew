// SPEC: nutrition addendum §4 ("three gram steppers") · 6.3 (≥ 44 pt targets) · clause ⑤ — one gram amount: − / + step by
// macroGramsRoundTo (a long press repeats, StepButton) and the number itself is typeable, because forty grams is eight taps
// otherwise. Whole grams inside 0…limit and NOTHING else is checked: no food is judged. Ink only — a macro colour is identity on a
// BAR, never on a control (§7.4). The text binding converts on every keystroke, so a Save tapped while the number pad is still up
// reads what is on screen (the A20.11 lesson: a `value:` binding commits only when the field loses focus). The number pad carries no
// return key: the screen that hosts these fields owns the keyboard's Done item and clears `focus` (A19.2).
// Twin of web components/nutrition/GramField.tsx. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct GramField: View {
    let label: String
    @Binding var grams: Int
    let limit: Int
    var focus: FocusState<String?>.Binding
    let key: String
    @ScaledMetric private var minTarget: CGFloat = CGFloat(SpecConstants.minTouchTargetPt) // 6.5: grows with Dynamic Type

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space8) {
            Text(label).font(.body.weight(.semibold)).foregroundStyle(EmberColors.inkText)
            Spacer(minLength: EmberTokens.Spacing.space8)
            StepButton(symbol: "minus", noun: label) { grams = GramField.clamp(grams - SpecConstants.macroGramsRoundTo, limit) }
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.body.monospacedDigit())
                .foregroundStyle(EmberColors.inkText)
                .focused(focus, equals: key)
                .frame(width: minTarget + EmberTokens.Spacing.space16, height: minTarget)
                .background(EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous).stroke(EmberColors.controlOutline, lineWidth: EmberTokens.Size.hairline)) // A18.11: a field's boundary is a control boundary
                .accessibilityLabel("\(label) grams")
            StepButton(symbol: "plus", noun: label) { grams = GramField.clamp(grams + SpecConstants.macroGramsRoundTo, limit) }
        }
    }

    // Digits only, clamped as they are typed: an invalid amount is unreachable rather than rejected
    private var text: Binding<String> {
        Binding(get: { String(grams) }, set: { grams = GramField.clamp(Int($0.filter(\.isNumber)) ?? 0, limit) })
    }

    static func clamp(_ grams: Int, _ limit: Int) -> Int {
        min(limit, max(0, grams))
    }
}

// The three of them, always in the fixed order Protein → Carbs → Fat (§7.4 encoder ①). `prefix` keeps two groups on one screen apart.
struct GramFields: View {
    @Binding var grams: MacroGrams
    let limit: Int
    var focus: FocusState<String?>.Binding
    var prefix = "grams"

    var body: some View {
        VStack(spacing: EmberTokens.Spacing.space8) {
            GramField(label: "Protein", grams: binding(\.proteinG, { MacroGrams(proteinG: $0, carbsG: grams.carbsG, fatG: grams.fatG) }), limit: limit, focus: focus, key: "\(prefix).protein")
            GramField(label: "Carbs", grams: binding(\.carbsG, { MacroGrams(proteinG: grams.proteinG, carbsG: $0, fatG: grams.fatG) }), limit: limit, focus: focus, key: "\(prefix).carbs")
            GramField(label: "Fat", grams: binding(\.fatG, { MacroGrams(proteinG: grams.proteinG, carbsG: grams.carbsG, fatG: $0) }), limit: limit, focus: focus, key: "\(prefix).fat")
        }
    }

    // MacroGrams is the engine's immutable value (three `let`s), so a change builds the next one
    private func binding(_ read: KeyPath<MacroGrams, Int>, _ next: @escaping (Int) -> MacroGrams) -> Binding<Int> {
        Binding(get: { grams[keyPath: read] }, set: { grams = next($0) })
    }
}
