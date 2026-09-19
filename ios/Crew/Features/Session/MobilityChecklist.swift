// SPEC: A28 (c), (f) (owner-approved 2026-09-19; design/targets 10) — the checklist screen: "Mobility" with "Mark all done" in its
// header, "N of M holds done" as the count line, and ONE card of name-plus-cue rows, each with a check. NO TIMERS: a hold is ticked,
// never counted down, and holdSeconds stays in the seed as data read by no screen. The only screen type with more than one tick
// target (§7). Job (R-083 (24)): tick the holds, finish — the screen's one filled button is Finish (SessionScreen).
// §10: at accessibility sizes the check moves below the cue. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct MobilityChecklist: View {
    let model: SessionModel

    private var doneCount: Int { model.holds.filter { hold in model.sets(of: hold).allSatisfy(\.done) }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space12) {
                    Text("Mobility").typeRole(EmberTokens.Typography.exerciseTitle).foregroundStyle(EmberColors.ink)
                    Spacer(minLength: EmberTokens.Spacing.space8)
                    if doneCount < model.holds.count {
                        TextActionButton(title: "Mark all done", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { model.markAllHolds() }
                    }
                }
                Text(numerals: "\(doneCount) of \(model.holds.count) holds done")
                    .typeRole(EmberTokens.Typography.secondary)
                    .foregroundStyle(EmberColors.inkSecondary)
            }
            FocusCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(model.holds.enumerated()), id: \.element.order) { index, hold in
                        if index > 0 {
                            Rectangle().fill(EmberColors.hairlineOnCard).frame(height: EmberTokens.Size.hairline).padding(.horizontal, EmberTokens.Focus.setCardInset)
                        }
                        HoldCheckRow(name: hold.name, cue: SeedCatalog.shared.exercise(hold.exerciseId)?.cueLine, done: model.sets(of: hold).allSatisfy(\.done)) { model.toggleHold(hold) }
                    }
                }
            }
        }
    }
}

// One hold: its name, its cue line, and the check (§8: a 44 pt target holding a 28 pt circle — a 2 pt ink ring when open, solid
// ink with an onInk tick when done). The whole row is the target, so the check is never a 28 pt aim.
struct HoldCheckRow: View {
    let name: String
    let cue: String?
    let done: Bool
    let onToggle: () -> Void
    @ScaledMetric private var circle: CGFloat = EmberTokens.Focus.checkCircle
    @ScaledMetric private var glyph: CGFloat = EmberTokens.Focus.checkGlyph
    @ScaledMetric private var target: CGFloat = CGFloat(SpecConstants.minTouchTargetPt)

    var body: some View {
        Button(action: onToggle) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: EmberTokens.Spacing.space12) { words; Spacer(minLength: EmberTokens.Spacing.space8); check }
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) { words; check }
            }
            .padding(.horizontal, EmberTokens.Focus.setCardInset)
            .padding(.vertical, EmberTokens.Focus.setRowPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(name)\(cue.map { ", \($0)" } ?? "")\(done ? ", done" : "")")
        .accessibilityHint(done ? "Double-tap to untick" : "Double-tap to tick")
    }

    private var words: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
            Text(name).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let cue {
                Text(cue).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var check: some View {
        ZStack {
            if done {
                Circle().fill(EmberColors.ink)
                Image(systemName: "checkmark").font(.system(size: glyph, weight: .bold)).foregroundStyle(EmberColors.onInk)
            } else {
                Circle().strokeBorder(EmberColors.ink, lineWidth: EmberTokens.Focus.checkRing)
            }
        }
        .frame(width: circle, height: circle)
        .frame(width: target, height: target)
    }
}
