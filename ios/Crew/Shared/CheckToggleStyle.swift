// SPEC: A28 (f) — the system's check (design/focus-card-system.md §8: a 44 pt target holding a 28 pt circle — a 2 pt ink ring when
// open, solid ink with an onInk tick when done) as the style of an on/off setting. The platform's switch tinted ink put its white
// knob on a cream track in dark (1.16:1, docs/debt.md "A28 R0 / theme"), and a switch is not on the component list; a check is, and
// reads the same in both modes. The whole row is the target. WRITTEN — UNVERIFIED (needs Mac). R6

import SwiftUI

struct CheckToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        CheckToggleRow(configuration: configuration)
    }
}

private struct CheckToggleRow: View {
    let configuration: ToggleStyleConfiguration
    @ScaledMetric private var circle: CGFloat = EmberTokens.Focus.checkCircle
    @ScaledMetric private var glyph: CGFloat = EmberTokens.Focus.checkGlyph
    @ScaledMetric private var rowHeight: CGFloat = EmberTokens.Focus.rowButton

    var body: some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: EmberTokens.Spacing.space12) {
                configuration.label.typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                Spacer(minLength: EmberTokens.Spacing.space8)
                ZStack {
                    if configuration.isOn {
                        Circle().fill(EmberColors.ink)
                        Image(systemName: "checkmark").font(.system(size: glyph, weight: .bold)).foregroundStyle(EmberColors.onInk)
                    } else {
                        Circle().strokeBorder(EmberColors.ink, lineWidth: EmberTokens.Focus.checkRing)
                    }
                }
                .frame(width: circle, height: circle)
                .frame(width: CGFloat(SpecConstants.minTouchTargetPt), height: CGFloat(SpecConstants.minTouchTargetPt))
            }
            .frame(maxWidth: .infinity, minHeight: rowHeight, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation { Toggle(isOn: configuration.$isOn) { configuration.label } } // VoiceOver reads a switch: "on" / "off"
    }
}
