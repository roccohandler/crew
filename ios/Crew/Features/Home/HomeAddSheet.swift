// SPEC: A28 (d) — cardio and a bonus workout live behind the "+" in Home's nav bar (amends A18.5's verb rows and A22 G4's row). It
// is the system's sheet (design/focus-card-system.md §7: a grabber, a title row, row buttons) and a ROUTE to two screens that
// already exist, not a screen with a job of its own (R-083 (22)): Log cardio in every state, a bonus workout where A3 / Flow 5
// offer one (a rest day, a done day). Each row is a full-width row button with its chevron (§8); nothing here is filled, so the
// sheet has no primary. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

enum HomeAddChoice {
    case cardio, bonus
}

struct HomeAddSheet: View {
    let offersBonus: Bool
    let onPick: (HomeAddChoice) -> Void
    @ScaledMetric private var rowHeight: CGFloat = EmberTokens.Focus.primaryHeightHome // §8: a row button is 56 pt minimum

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Add to today").typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink)
                .padding(.horizontal, EmberTokens.Focus.gutter)
                .padding(.top, EmberTokens.Focus.gutter)
                .padding(.bottom, EmberTokens.Spacing.space12)
            row("Log cardio") { onPick(.cardio) }
            if offersBonus {
                Rectangle().fill(EmberColors.hairlineOnCard).frame(height: EmberTokens.Size.hairline).padding(.leading, EmberTokens.Focus.gutter)
                row("Bonus workout") { onPick(.bonus) }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EmberColors.card.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func row(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: EmberTokens.Spacing.space12) {
                Text(title).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                Spacer(minLength: EmberTokens.Spacing.space8)
                Image(systemName: "chevron.right").foregroundStyle(EmberColors.chevron)
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .frame(maxWidth: .infinity, minHeight: rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
