// SPEC: nutrition addendum §4 (Today: P / C / F and, fourth, Calories — Q2) · ux-plan §7.4 — ALL FIVE redundant encoders, so the
// screen is fully correct with every macro token forced to plain ink: ① fixed order Protein → Carbs → Fat, never sorted; ② a P / C / F
// letter in INK on every coloured element; ③ direct numbers on every bar; ④ fill treatment — protein solid · carbs solid + an ink
// hairline · fat an OUTLINE + an ink hairline; ⑤ state is never colour — "N to go" / "N over" are ink words on their own line (clause ②)
// and an overage shows as LENGTH past the target marker, an ink hairline at macroBarTargetPercent of the track. Calories is ink text
// with no bar: it has no macro identity. The three macro tokens render HERE and nowhere else in the app; no ember element and no
// semantic token shares this surface (law ⑥'s one bounded exception). Every string comes from the MacroDay twin.
// Twin of web components/nutrition/MacroLines.tsx. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

enum MacroFillTreatment {
    case solid, solidWithHairline, outlineWithHairline
}

struct MacroLines: View {
    let remaining: MacroRemaining

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            MacroBarRow(letter: "P", name: "Protein", line: remaining.protein, fill: EmberColors.macroProtein, track: EmberColors.macroProteinTrack, treatment: .solid)
            MacroBarRow(letter: "C", name: "Carbs", line: remaining.carbs, fill: EmberColors.macroCarbs, track: EmberColors.macroCarbsTrack, treatment: .solidWithHairline)
            MacroBarRow(letter: "F", name: "Fat", line: remaining.fat, fill: EmberColors.macroFat, track: EmberColors.macroFatTrack, treatment: .outlineWithHairline)
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                MacroLineHeader(letter: nil, name: "Calories", amount: MacroDay.amountText(remaining.calories, unit: "kcal"))
                if let rest = MacroDay.restText(remaining.calories) { MacroRestLine(text: rest) }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(MacroDay.spokenLine("Calories", remaining.calories, unit: "kcal"))
            if let horizon = MacroDay.horizonText(remaining) { MacroRestLine(text: horizon) } // clause ②: an overage names tomorrow in the same breath
        }
    }
}

struct MacroBarRow: View {
    let letter: String
    let name: String
    let line: MacroLine
    let fill: Color
    let track: Color
    let treatment: MacroFillTreatment

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
            MacroLineHeader(letter: letter, name: name, amount: MacroDay.amountText(line, unit: "g"))
            MacroBar(percent: MacroDay.barPercent(line), fill: fill, track: track, treatment: treatment)
            if let rest = MacroDay.restText(line) { MacroRestLine(text: rest) }
        }
        // E20 — one stop per line, the whole sentence: "Protein: 95 / 145 g, 50 to go"
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(MacroDay.spokenLine(name, line, unit: "g"))
    }
}

struct MacroLineHeader: View {
    let letter: String?
    let name: String
    let amount: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space8) {
            if let letter { Text(letter).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink) }
            Text(name).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
            Spacer(minLength: EmberTokens.Spacing.space8)
            Text(numerals: amount).typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.ink)
        }
    }
}

struct MacroRestLine: View {
    let text: String

    var body: some View {
        Text(numerals: text).typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.ink) // clause ②: ordinary ink, on its own line
    }
}

struct MacroBar: View {
    let percent: Int
    let fill: Color
    let track: Color
    let treatment: MacroFillTreatment
    @ScaledMetric private var height: CGFloat = EmberTokens.Spacing.space12

    var body: some View {
        GeometryReader { proxy in
            let unit = proxy.size.width / CGFloat(SpecConstants.macroPercentScale)
            ZStack(alignment: .leading) {
                Rectangle().fill(track)
                if percent > 0 { filled.frame(width: unit * CGFloat(percent)) }
                Rectangle().fill(EmberColors.ink).frame(width: EmberTokens.Size.hairline).offset(x: unit * CGFloat(SpecConstants.macroBarTargetPercent))
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: EmberTokens.Spacing.space4, style: .continuous))
        .accessibilityHidden(true)
    }

    // Encoder ④ — the fill treatment is the third channel: it reads in greyscale, where protein and fat share a lightness
    @ViewBuilder private var filled: some View {
        switch treatment {
        case .solid:
            Rectangle().fill(fill)
        case .solidWithHairline:
            Rectangle().fill(fill).overlay(Rectangle().strokeBorder(EmberColors.ink, lineWidth: EmberTokens.Size.hairline))
        case .outlineWithHairline:
            Rectangle().strokeBorder(fill, lineWidth: EmberTokens.Spacing.space4)
                .overlay(Rectangle().inset(by: EmberTokens.Spacing.space4).strokeBorder(EmberColors.ink, lineWidth: EmberTokens.Size.hairline))
        }
    }
}
