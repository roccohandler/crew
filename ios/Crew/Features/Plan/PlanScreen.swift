// SPEC: S14 Plan · A4 (owner-directed 2026-09-08) as amended by A27 (a) and A28 (d), (f) — the week map: the page's own title, the
// rotation-and-forward-only line (A4), then ONE card of seven rows from the rotation projection (A1) — a workout day is a row button
// that opens WorkoutEditorScreen, a rest or open day a quiet row — `Next week starts with {name}` when the cycle does not divide the
// days, and a second card of row buttons: `Change days` (DaysSheet) and `Rebuild my week` (the questions again). Save returns here
// and says `Saved · applies from your next {name}` as a quiet line (A28 (f): no toast), tapped away. States: loading · ready · empty
// · error · offline. Screens hold ZERO logic (5.6.6). WRITTEN — UNVERIFIED (needs Mac). R4

import SwiftUI

enum PlanLoadState: Equatable {
    case loading
    case ready
    case empty
    case failed(String)
    case offline // 6.1 five states: the plan lives on the phone, so offline renders the week map with a banner
}

struct PlanScreen: View {
    @State private var model = PlanModel()
    @State private var loadState: PlanLoadState = .loading
    @State private var path: [String] = []   // the workout kind being edited (A4: one level down)
    @State private var changingDays = false
    @State private var rebuilding = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space24) {
                    Text("Plan").typeRole(EmberTokens.Typography.screenTitle).foregroundStyle(EmberColors.ink).accessibilityAddTraits(.isHeader)
                    content
                }
                .padding(.horizontal, EmberTokens.Focus.gutter)
                .padding(.top, EmberTokens.Spacing.space32)
                .padding(.bottom, EmberTokens.Spacing.space24)
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Plan")
            .toolbar(.hidden, for: .navigationBar) // the title is the page's own; the editor keeps its bar
            .navigationDestination(for: String.self) { kind in
                WorkoutEditorScreen(model: model, kind: kind) { path.removeAll() }
            }
            .onAppear { load() }
            .sheet(isPresented: $changingDays) { DaysSheet(model: model) { changingDays = false } }
            .sheet(isPresented: $rebuilding) { OnboardingFlow(mode: .rebuild) { rebuilding = false; load() }.presentationDragIndicator(.visible) }
        }
        .tint(EmberColors.ink)
    }

    @ViewBuilder private var content: some View {
        switch loadState {
        case .loading: FocusCard { LoadingLine(line: "Opening your week…") } // 6.1 (2026-09-18): a line, not a skeleton
        case .ready: weekMap
        case .offline: VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) { OfflineBanner(lastSyncedLine: "Your plan is on this phone — edits sync later."); weekMap }
        case .empty: empty
        case .failed(let line): ErrorState(line: line) { load() }
        }
    }

    private var weekMap: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            if let line = model.savedLine {
                Button { model.dismissSaved() } label: {
                    Text(line).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink).frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt), alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Dismisses")
            }
            Text("Workouts rotate Push → Pull → Legs, so each gets equal time. Changes apply from your next workout on.")
                .typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary).fixedSize(horizontal: false, vertical: true)
            FocusCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(model.rows.enumerated()), id: \.element.id) { index, row in
                        if index > 0 { seam }
                        PlanDayRow(row: row) { if let kind = row.kind { path = [kind] } }
                    }
                }
            }
            if let name = model.nextWeekStartsWith {
                Text("Next week starts with \(name)").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
            }
            FocusCard(padding: 0) {
                VStack(spacing: 0) {
                    RowButton(title: "Change days") { changingDays = true }
                    seam
                    RowButton(title: "Rebuild my week") { rebuilding = true }
                }
            }
            if let line = model.errorLine { Text(line).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink) }
        }
    }

    // SPEC: 6.1 — empty is an invitation with exactly one CTA; A21.1 asks two questions (the words Home's no-plan card uses)
    private var empty: some View {
        FocusCard {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                Text("No plan yet").typeRole(EmberTokens.Typography.cardSubheading).foregroundStyle(EmberColors.ink)
                Text("Two questions and your plan is ready.").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                PrimaryButton(title: "Build my week") { rebuilding = true }.padding(.top, EmberTokens.Spacing.space8)
            }
        }
    }

    private var seam: some View {
        Rectangle().fill(EmberColors.hairlineOnCard).frame(height: EmberTokens.Size.hairline).padding(.leading, EmberTokens.Focus.setCardInset)
    }

    private func load() {
        model.load()
        if let line = model.errorLine { loadState = .failed(line) } else { loadState = model.hasPlan ? .ready : .empty }
    }
}

// SPEC: A4 · A28 (f) — one day of the week map inside the card: a workout day is a row button (§8: name, value, chevron, 56 pt
// minimum) that opens the editor; a rest or open day is a quiet row with no chevron (A8: never a verdict)
struct PlanDayRow: View {
    let row: WeekMapRow
    let onTap: () -> Void

    var body: some View {
        if row.kind != nil {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
                .accessibilityLabel(label)
                .accessibilityHint("Opens the workout")
        } else {
            content.accessibilityElement(children: .combine).accessibilityLabel(label)
        }
    }

    private var label: String { row.detail.map { "\(row.title). \($0)" } ?? row.title }

    private var content: some View {
        HStack(spacing: EmberTokens.Spacing.space12) {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                Text(row.title).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(row.quiet ? EmberColors.inkSecondary : EmberColors.ink)
                if let detail = row.detail { Text(numerals: detail).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary) }
            }
            Spacer(minLength: EmberTokens.Spacing.space8)
            if row.kind != nil { Image(systemName: "chevron.right").foregroundStyle(EmberColors.chevron) }
        }
        .padding(.horizontal, EmberTokens.Focus.setCardInset)
        .padding(.vertical, EmberTokens.Spacing.space8)
        .frame(maxWidth: .infinity, minHeight: EmberTokens.Focus.rowButton, alignment: .leading)
        .contentShape(Rectangle())
    }
}

