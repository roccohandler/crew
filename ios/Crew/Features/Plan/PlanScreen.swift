// SPEC: S14 Plan · A4 (owner-directed 2026-09-08) — the week map: seven rows from the rotation projection (A1), zero
// controls in the rows; forward-only stated in copy; `Next week starts with {name}` when the cycle does not divide the
// days; `Change days` (DaysSheet) and `Rebuild my week` (the questions again). A row opens WorkoutEditorScreen, pushed
// full screen. Save returns here with the toast `Saved · applies from your next {name}`. States: loading · ready · empty
// · error. Screens hold ZERO logic (5.6.6). WRITTEN — UNVERIFIED (needs Mac).

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
            Group {
                switch loadState {
                case .loading: ListSkeleton(rows: TimeUnits.daysPerWeek)
                case .ready: weekMap
                case .offline: VStack(spacing: 0) { OfflineBanner(lastSyncedLine: "Your plan is on this phone — edits sync later."); weekMap }
                case .empty: EmptyState(title: "No plan yet", line: "Answer three questions and your week is built.", ctaTitle: "Build my week") { rebuilding = true }
                case .failed(let line): ErrorState(line: line) { load() }
                }
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Plan")
            .navigationDestination(for: String.self) { kind in
                WorkoutEditorScreen(model: model, kind: kind) { path.removeAll() }
            }
            .onAppear { load() }
            .sheet(isPresented: $changingDays) { DaysSheet(model: model) { changingDays = false } }
            .sheet(isPresented: $rebuilding) { OnboardingFlow(mode: .rebuild) { rebuilding = false; load() } }
            .overlay(alignment: .bottom) {
                if let line = model.savedLine { BoneToast(line: line) { model.dismissSaved() } }
            }
        }
        .tint(EmberColors.inkText)
    }

    private var weekMap: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                Text("Workouts rotate Push → Pull → Legs, so each gets equal time. Changes apply from your next workout on.")
                    .font(.footnote).foregroundStyle(EmberColors.secondaryText)
                ForEach(model.rows) { row in
                    WeekRow(row: row) { if let kind = row.kind { path = [kind] } }
                }
                if let name = model.nextWeekStartsWith {
                    Text("Next week starts with \(name)").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                }
                SecondaryButton(title: "Change days") { changingDays = true }
                SecondaryButton(title: "Rebuild my week") { rebuilding = true }
                if let line = model.errorLine { Text(line).font(.footnote).foregroundStyle(EmberColors.inkText) }
            }
            .padding(EmberTokens.Spacing.space16)
            .padding(.bottom, CGFloat(SpecConstants.minTouchTargetPt) + EmberTokens.Spacing.space32) // room for the toast: its height plus its margins
        }
    }

    private func load() {
        model.load()
        if let line = model.errorLine { loadState = .failed(line) } else { loadState = model.hasPlan ? .ready : .empty }
    }
}

// A transient bone card with one ink line — saving is not a reward, so never orange (Part III); tap dismisses
struct BoneToast: View {
    let line: String
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onDismiss) {
            Text(line)
                .font(.subheadline)
                .foregroundStyle(EmberColors.inkText)
                .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                .padding(.horizontal, EmberTokens.Spacing.space16)
                .background(EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous))
                // A18.11 — the BoneToast, whose whole surface is a Button (tap dismisses): a control boundary, so controlOutline (3.32:1 on a card, 3.13:1 on the canvas) and never
                // the 1.26:1 hairline family, which is for the seam between two surfaces.
                .overlay(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous).stroke(EmberColors.controlOutline, lineWidth: EmberTokens.Size.hairline))
        }
        .buttonStyle(.plain)
        .padding(EmberTokens.Spacing.space16)
        .accessibilityLabel(line)
        .accessibilityHint("Dismisses")
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
