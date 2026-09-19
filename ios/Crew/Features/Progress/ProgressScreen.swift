// SPEC: S15 Progress as amended by A28 (b), (d), (e), (f) (owner-approved 2026-09-19; design/targets 12) — the data screen (GAP 1
// read by R-086: the type the approved mockup draws, for Progress alone): a large title, ONE fact line — "This season · N weeks · N
// workouts" (A28 (e); GAP 10, SeasonFacts) — and one card carrying the figure, the heat map; no accent anywhere. Tap a day → that
// day's workouts (Flow 9 layer 1). Under the card two row buttons keep A19.4's promise that both halves of Flow 9 sit one tap from
// the tab (its segmented control is not on A28 (f)'s component list): Charts (layers 2–3) and the Journal (S16). W6: the empty
// state's one CTA goes to today. 6.1: loading is a quiet line, a Store error is the failed state with Try again.
// WRITTEN — UNVERIFIED (needs Mac). T040 · R3

import SwiftUI

enum ProgressLoadState: Equatable {
    case loading
    case ready
    case empty
    case failed(String)
    case offline
}

enum ProgressDestination: Hashable {
    case charts, journal
}

struct ProgressScreen: View {
    var onGoHome: () -> Void = {}
    var journalRequested: Binding<Bool> = .constant(false) // A28 (d) · R-083 (18): Home's "Edit today's log" lands on the Journal
    @State private var model = ProgressModel()
    @State private var loadState: ProgressLoadState = .loading
    @State private var selected: DayDetail?
    @State private var path: [ProgressDestination] = []
    private var units: String { AuthStore.shared.weightUnit } // A9
    private var userId: String { AuthStore.shared.currentUser?.id ?? "local" }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space24) {
                    VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                        Text("Progress").typeRole(EmberTokens.Typography.screenTitle).foregroundStyle(EmberColors.ink).accessibilityAddTraits(.isHeader)
                        if loadState == .ready, let season = model.season {
                            Text(numerals: season.line).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                        }
                    }
                    content
                }
                .padding(.horizontal, EmberTokens.Focus.gutter)
                .padding(.top, EmberTokens.Spacing.space32)
                .padding(.bottom, EmberTokens.Spacing.space24)
            }
            // SPEC: 6.3 (DESIGN.md 4.2) — the empty state's one primary is bottom-anchored in the thumb zone, not inside its card
            // (ui-reviewer, run 35444308817)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if loadState == .empty {
                    PrimaryButton(title: "Go to today", action: onGoHome)
                        .padding(.horizontal, EmberTokens.Focus.gutter)
                        .padding(.vertical, EmberTokens.Spacing.space12)
                }
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Progress")
            .toolbar(.hidden, for: .navigationBar) // the title is the page's own (mockup 12); pushed screens keep their bar
            .navigationDestination(for: ProgressDestination.self) { destination in
                switch destination {
                case .charts: ChartsScreen(model: model, units: units)
                case .journal: journal
                }
            }
            .onAppear { if journalRequested.wrappedValue { path = [.journal]; journalRequested.wrappedValue = false } }
            .onChange(of: journalRequested.wrappedValue) { _, asked in if asked { path = [.journal]; journalRequested.wrappedValue = false } }
            .task { load() }
        }
    }

    @ViewBuilder private var content: some View {
        switch loadState {
        case .loading: FocusCard { LoadingLine(line: "Adding up your weeks…") } // 6.1 (2026-09-18): a line, not a skeleton
        case .empty: empty
        case .failed(let line): ErrorState(line: line) { load() }
        case .ready, .offline: filled
        }
    }

    private var filled: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            FocusCard { HeatMapView(days: model.heatMap, todayKey: model.todayKey, selected: selected?.dayKey) { selected = model.select($0) } }
            if let selected { dayCard(selected) }
            FocusCard(padding: 0) {
                VStack(spacing: 0) {
                    RowButton(title: "Charts") { path = [.charts] }
                    Rectangle().fill(EmberColors.hairlineOnCard).frame(height: EmberTokens.Size.hairline).padding(.leading, EmberTokens.Focus.setCardInset)
                    RowButton(title: "Journal") { path = [.journal] }
                }
            }
        }
    }

    // SPEC: 6.1 · W6 — empty is an invitation with exactly one CTA: today, where the first workout starts
    private var empty: some View {
        FocusCard {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                Text("Your first post starts the story").typeRole(EmberTokens.Typography.cardSubheading).foregroundStyle(EmberColors.ink)
                Text("Every workout you complete lands here.").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // SPEC: A6 — the journal reads the Store each time it is built: every post, plus the plan's training-days history (A1 · A27 (a))
    // for rest-day labels
    private var journal: some View {
        JournalScreen(posts: (try? Store.shared.allPosts(for: userId)) ?? [], trainingDays: (try? PlanLocal.trainingDays(for: userId, store: .shared)) ?? [], distanceUnit: AuthStore.shared.distanceUnit, onDelete: { post in
            post.deletedAt = Date()
            try? Store.shared.save()
            try? SyncQueue.shared.enqueue(.deletePost, payload: ["clientId": post.clientId])
            load()
        }, onGoHome: onGoHome)
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.inline)
    }

    // SPEC: Flow 9 layer 1 — the day card: its DayLabel (A6), that day's workouts in the journal's own sentence (no minutes, A28 (c))
    private func dayCard(_ detail: DayDetail) -> some View {
        FocusCard {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                Text(DayLabel.dayLabel(detail.dayKey, todayKey: model.todayKey)).typeRole(EmberTokens.Typography.eyebrow).foregroundStyle(EmberColors.inkSecondary)
                ForEach(detail.workouts, id: \.self) { Text(numerals: $0).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink) }
                if detail.workouts.isEmpty { Text("Nothing that day. Tomorrow's a fresh one.").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary) }
            }
        }
    }

    // SPEC: 6.1 — loading → ready / empty / failed: a Store error names what to do and offers Try again
    private func load() {
        do {
            try model.refresh()
            loadState = model.isEmpty ? .empty : .ready
        } catch {
            loadState = .failed(AppError.storage("progress").userLine)
        }
    }
}
