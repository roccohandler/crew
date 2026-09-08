// SPEC: S14 Plan editor — Mon–Sun at a glance (Flow 8); tiered editing (swap / tune / full); limits enforced by input constraints
// (invalid states unreachable); Rebuild = the questions again; forward-only stated in copy; states: loading · ready · empty ·
// error · offline · undo. Screens hold ZERO logic (5.6.6). WRITTEN — UNVERIFIED (needs Mac). S14 iOS (see PlanModel header)

import SwiftUI

enum PlanLoadState: Equatable {
    case loading
    case ready
    case empty
    case failed(String)
    case offline
}

struct PlanScreen: View {
    @State private var model = PlanModel()
    @State private var loadState: PlanLoadState = .loading
    @State private var swapping: (weekday: Int, row: PlanDraftExercise)?
    @State private var addingTo: Int?
    @State private var rebuilding = false

    var body: some View {
        NavigationStack {
            Group {
                switch loadState {
                case .loading: ListSkeleton(rows: TimeUnits.daysPerWeek)
                case .ready, .offline: editor
                case .empty: EmptyState(title: "No plan yet", line: "Answer three questions and your week is built.", ctaTitle: "Build my week") { rebuilding = true }
                case .failed(let line): ErrorState(line: line) { load() }
                }
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Plan")
            .task { load() }
            .sheet(isPresented: Binding(get: { swapping != nil }, set: { if !$0 { swapping = nil } })) {
                SwapSheet(candidates: swapping.map { model.swapCandidates(for: $0.row.exerciseId, in: $0.weekday) } ?? []) { pick in
                    if let swapping { model.swap(exerciseId: swapping.row.exerciseId, in: swapping.weekday, with: pick) }
                    swapping = nil
                }
            }
            .sheet(isPresented: Binding(get: { addingTo != nil }, set: { if !$0 { addingTo = nil } })) {
                SwapSheet(candidates: addingTo.map { model.addCandidates(for: $0) } ?? []) { pick in
                    if let addingTo { model.add(pick, to: addingTo) }
                    addingTo = nil
                }
            }
            .sheet(isPresented: $rebuilding) { OnboardingFlow(mode: .rebuild) { rebuilding = false; load() } }
        }
    }

    private var editor: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                if loadState == .offline { OfflineBanner(lastSyncedLine: "Your plan is on this phone — edits sync later.") }
                Text("Everything applies forward. History never rewrites.").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                ForEach(model.week) { slot in
                    PlanDayCard(slot: slot, model: model, onSwap: { row in swapping = (slot.weekday, row) }, onAdd: { addingTo = slot.weekday })
                }
                PrimaryButton(title: "Save plan") { model.save() }
                if model.previous != nil { SecondaryButton(title: "Undo") { model.undo() } }
                if let line = model.savedLine { Text(line).font(.footnote).foregroundStyle(EmberColors.secondaryText) }
                if let line = model.errorLine { Text(line).font(.footnote).foregroundStyle(EmberColors.danger) }
                SecondaryButton(title: "Rebuild my week") { rebuilding = true }
            }
            .padding(EmberTokens.Spacing.space16)
        }
    }

    private func load() {
        model.load()
        if let line = model.errorLine { loadState = .failed(line) } else { loadState = model.hasPlan ? .ready : .empty }
    }
}
