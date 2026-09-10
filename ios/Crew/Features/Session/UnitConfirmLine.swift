// SPEC: A9 (owner-directed 2026-09-09) — the units question is asked ONCE, in context, at the first moment it matters:
// the top of the first Session screen, not a fourth onboarding question. The default already came from the device
// (MeasurementSystemHint), so the common case is one tap on "Yes"; the ~10% the locale gets wrong flip it in one more.
// It is one ink line and two ink controls — never a modal, never a blocking sheet, never ember (Part III law ①/④), and it
// never returns once answered. Settings keeps both preferences changeable forever after (S17). Screens hold zero logic
// (5.6.6): the decision to show it is a stored flag, the consequence is the model's. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct UnitConfirmLine: View {
    let weightUnit: String
    let onKeep: () -> Void
    let onFlip: () -> Void

    private var otherUnit: String { weightUnit == "lb" ? "kg" : "lb" }

    var body: some View {
        // ViewThatFits, like SetRow: at accessibility sizes the two controls drop under the line rather than truncating (6.7)
        ViewThatFits(in: .horizontal) {
            HStack(spacing: EmberTokens.Spacing.space12) {
                line
                Spacer(minLength: 0)
                controls
            }
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                line
                controls
            }
        }
        .padding(EmberTokens.Spacing.space12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous).stroke(EmberColors.hairline, lineWidth: EmberTokens.Size.hairline))
        .accessibilityElement(children: .contain)
    }

    private var line: some View {
        Text("Logging in \(weightUnit).")
            .font(.subheadline)
            .foregroundStyle(EmberColors.inkText)
            .fixedSize(horizontal: false, vertical: true)
    }

    // Two ink controls, both ≥ 44 pt (6.3). Neither is a filled primary: the screen's one primary is Complete workout.
    private var controls: some View {
        HStack(spacing: EmberTokens.Spacing.space12) {
            Button(action: onKeep) {
                Text("Yes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(EmberColors.inkText)
                    .frame(minWidth: CGFloat(SpecConstants.minTouchTargetPt), minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Keep logging in \(weightUnit)")

            Button(action: onFlip) {
                Text("Use \(otherUnit)")
                    .font(.subheadline)
                    .foregroundStyle(EmberColors.inkText)
                    .frame(minWidth: CGFloat(SpecConstants.minTouchTargetPt), minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Switch to \(otherUnit)")
        }
    }
}
