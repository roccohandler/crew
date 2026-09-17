// SPEC: A20.1 / A20.2 / A20.3 (owner-directed 2026-09-11) — TODAY'S LOG: one list, three rows, one grammar.
//
// WHY THIS REPLACES VectorRow AND THE WORKOUT CARD. A14 made Workout · Cardio · Meals co-equal and A18.5 gave them a
// verb and a full-width row — but the day's WORKOUT still lived in a card above them, with its own ink-filled primary.
// So one intent was reachable from three controls at three weights: the card's "Start workout", a "Quick complete"
// secondary beneath it, and a "Log workout" row whose handler is byte-identical to the card's. With a session open it
// was four, because a "Resume workout · Push day" banner appeared at the top as well. That is the owner's "things
// don't look like they're syncing": one screen, one day, four different ways of saying the same thing.
//
// The rules this file encodes, each one an owner ruling of 2026-09-11:
//
//   A20.2 VERB TITLE, STATUS SUBTITLE. The title stays the verb (6.6, A18.5 reaffirmed) and the subtitle reports what
//     today holds. A18.5's SILENCE clause is what changes: an unlogged row used to render no trailing element at all,
//     so a row nobody had touched and a row whose post failed to send looked identical. Every row now says something.
//   A20.3 ONE TARGET PER ROW, WITH EXACTLY ONE NAMED EXCEPTION. The whole row is the button and a chevron says so —
//     not a row that is tappable AND carries an inner "Log" pill, which is the nested-target pattern eBay's and
//     Material's design systems both forbid and which forces either two VoiceOver stops per row or one that swallows
//     the pill. THE EXCEPTION IS THE WORKOUT ROW'S QUICK-COMPLETE MARK, and it is named here so it cannot spread: it
//     absorbs the "Quick complete" button S07 requires and Flow 3 has nowhere else, and it is the only inner control
//     on any row in the app.
//   A20.12 ember is NEVER worn by a row. A done row carries a filled INK dot — law ① (every control is ink) and law ④
//     (ember stays scarce for the flame, the fraction and the strip). The mockup's orange check breaks both, and its
//     white glyph on Crew's ratified dark ember measures 2.61:1 against 6.5's release-blocking 3:1 gate.
//
// A8 — no branch here prints a zero: an untouched row says what it is FOR, never "0".
// 6.3 — the row is its own ≥ 44 pt target, guaranteed by the frame and contentShape rather than inherited.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

// The facts one row reports. Built by HomeModel+Rows (5.6.6: a screen holds zero logic).
struct HomeLogRow: Equatable, Identifiable {
    let id: String        // "workout" · "cardio" · "meal" — stable, so the list never re-identifies a row mid-update
    let verb: String      // "Log workout"
    let detail: String    // "Push day · 5 exercises" · "8 of 15 sets" · "Not logged today"
    let glyph: String     // an SF Symbol, ink, no tile (A20 ruling: no fourth surface treatment, no fifth radius)
    let done: Bool        // the filled ink dot
    let offersQuickComplete: Bool // the ONE exception of A20.3, and only ever on the workout row
}

struct LogRowList: View {
    let rows: [HomeLogRow]
    let onTap: (HomeLogRow) -> Void
    let onQuickComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    // A divider BETWEEN two surfaces is not a control, so it keeps `hairline` — the A18.11 distinction
                    Rectangle().fill(EmberColors.hairline).frame(height: EmberTokens.Size.hairline)
                }
                LogRow(row: row, action: { onTap(row) }, onQuickComplete: onQuickComplete)
            }
        }
        // One boundary around the group, not three: the rows are peers, and three outlines would put two hairlines
        // between every pair. `controlOutline` (A18.11), never the surface hairline.
        .overlay(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous).stroke(EmberColors.controlOutline, lineWidth: EmberTokens.Size.hairline))
        .clipShape(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous))
    }
}

struct LogRow: View {
    let row: HomeLogRow
    let action: () -> Void
    let onQuickComplete: () -> Void
    @ScaledMetric private var minTarget: CGFloat = CGFloat(SpecConstants.minTouchTargetPt) // 6.5: the row grows with Dynamic Type

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space12) {
            Button(action: action) {
                HStack(spacing: EmberTokens.Spacing.space12) {
                    Image(systemName: row.glyph)
                        .font(EmberTokens.Typography.rowTitle)
                        .foregroundStyle(EmberColors.secondaryText)
                        .frame(width: EmberTokens.Spacing.space24) // one column, so three rows share a text edge (grid, A20)
                    VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                        Text(row.verb)
                            .font(EmberTokens.Typography.rowTitle)
                            .foregroundStyle(EmberColors.inkText)
                        Text(row.detail)
                            .font(EmberTokens.Typography.rowDetail)
                            .foregroundStyle(EmberColors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true) // 6.7: it wraps inside its own row, never truncates
                    }
                    .multilineTextAlignment(.leading)
                    Spacer(minLength: EmberTokens.Spacing.space8)
                    if row.done {
                        // The redundant encoder (6.5 / WCAG 1.4.1): the shape says logged without anyone reading the
                        // words. Ink, never ember — law ① and law ④.
                        Circle()
                            .fill(EmberColors.inkText)
                            .frame(width: EmberTokens.Spacing.space8, height: EmberTokens.Spacing.space8)
                    }
                    Image(systemName: "chevron.right")
                        .font(EmberTokens.Typography.caption)
                        .foregroundStyle(EmberColors.controlOutline)
                }
                .frame(maxWidth: .infinity, minHeight: minTarget, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            // E20 — the Button trait already says it is actionable, so the verb is not repeated as a value.
            .accessibilityLabel("\(row.verb), \(row.detail)")
            if row.offersQuickComplete { quickComplete }
        }
        .padding(.horizontal, EmberTokens.Spacing.space16)
        .padding(.vertical, EmberTokens.Spacing.space12)
    }

    // SPEC: A20.3's ONE named exception · S07 ("≤3 taps launch→fast-logged", "Quick Complete hidden once today counts")
    // · Flow 3 — the phone-free log. It was a full-width secondary button between the card and the rows, which made it
    // the only element that ever sat there and moved everything below it when it appeared. As the workout row's own
    // trailing control it keeps the capability and the tap count, and stops being a third weight on the screen.
    private var quickComplete: some View {
        Button(action: onQuickComplete) {
            Image(systemName: "checkmark")
                .font(EmberTokens.Typography.rowTitle)
                .foregroundStyle(EmberColors.inkText)
                .frame(minWidth: minTarget, minHeight: minTarget)
                .overlay(Circle().stroke(EmberColors.controlOutline, lineWidth: EmberTokens.Size.hairline))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Quick complete")
        .accessibilityHint("Logs today's workout without opening it")
    }
}
