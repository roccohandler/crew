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
    @ScaledMetric private var rowHeight: CGFloat = EmberTokens.Focus.rowButton // §8: a row button is 56 pt minimum
    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat = 0 // the sheet is as tall as its rows, not half the phone (6.9: no empty surface)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space12) {
                Text("Add to today").typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink).accessibilityAddTraits(.isHeader)
                Spacer(minLength: EmberTokens.Spacing.space8)
                TextActionButton(title: "Cancel", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { dismiss() } // 6.3: the pull has a visible twin (R-094)
            }
                .padding(.horizontal, EmberTokens.Focus.gutter)
                .padding(.top, EmberTokens.Focus.gutter)
                .padding(.bottom, EmberTokens.Spacing.space12)
            row("Log cardio", id: "home.add.cardio") { onPick(.cardio) }
            if offersBonus {
                Rectangle().fill(EmberColors.hairlineOnCard).frame(height: EmberTokens.Size.hairline).padding(.leading, EmberTokens.Focus.gutter)
                row("Bonus workout", id: "home.add.bonus") { onPick(.bonus) }
            }
        }
        .padding(.bottom, EmberTokens.Focus.gutter)
        .background(GeometryReader { proxy in Color.clear.onAppear { contentHeight = proxy.size.height } })
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(EmberColors.card.ignoresSafeArea())
        .presentationDetents(contentHeight > 0 ? [.height(contentHeight)] : [.medium])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(EmberTokens.Focus.cardRadius) // §8: 28 pt for a sheet's top corners
    }

    // `id` because on a training day the "+" itself is labelled "Log cardio": the tests tell the two apart by identifier
    private func row(_ title: String, id: String, action: @escaping () -> Void) -> some View {
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
        .accessibilityIdentifier(id)
    }
}
