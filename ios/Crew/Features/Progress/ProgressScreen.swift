// SPEC: S15 Progress — LAYER 1 did I show up (heat map → day detail with the day's workouts; rings history; streaks; totals —
// A22: the plates and meals/week left with the plate journal) · LAYER 2 how much work (sets/week, Push/Pull/Legs balance, cardio and mobility minutes — A2) · LAYER 3 am I
// stronger (only where weights were logged) · empty (new user) invites. A6: week captions and the day card read the DayLabel twin.
// 6.1: a Store error is the failed state with Try again. A19.4 (owner-ruled; built in W6, 2026-09-17): a two-way SEGMENT at the top
// — Charts | Journal — so both halves of Flow 9 are one tap from the tab and neither hides in chrome (the toolbar "Journal" button is
// gone). W6, the owner's walkthrough: the empty state's CTA goes to TODAY (Home, where the first workout starts) instead of opening
// a composer. WRITTEN — UNVERIFIED (needs Mac). T040

import SwiftUI

enum ProgressLoadState: Equatable {
    case loading
    case ready
    case empty
    case failed(String)
    case offline
}

enum ProgressSegment: Hashable {
    case charts, journal
}

struct ProgressScreen: View {
    var onGoHome: () -> Void = {}
    var journalRequested: Binding<Bool> = .constant(false) // A28 (d) · R-083 (18): Home's "Edit today's log" lands on the Journal
    @State private var model = ProgressModel()
    @State private var loadState: ProgressLoadState = .loading
    @State private var selected: DayDetail?
    @State private var segment: ProgressSegment = .charts
    private var units: String { AuthStore.shared.weightUnit } // A9
    private var userId: String { AuthStore.shared.currentUser?.id ?? "local" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // SPEC: A19.4 — the segment is the screen's first row; the five-tab bar is unchanged
                Picker("Progress view", selection: $segment) {
                    Text("Charts").tag(ProgressSegment.charts)
                    Text("Journal").tag(ProgressSegment.journal)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, EmberTokens.Spacing.space16)
                .padding(.top, EmberTokens.Spacing.space8)
                Group {
                    switch segment {
                    case .charts: charts
                    case .journal: journal
                    }
                }
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Progress")
            .onAppear { if journalRequested.wrappedValue { segment = .journal; journalRequested.wrappedValue = false } }
            .onChange(of: journalRequested.wrappedValue) { _, asked in if asked { segment = .journal; journalRequested.wrappedValue = false } }
            .task { load() }
        }
    }

    @ViewBuilder private var charts: some View {
        switch loadState {
        case .loading: LoadingLine(line: "Adding up your weeks…").padding(EmberTokens.Spacing.space16) // 6.1 (2026-09-18): a line, not a skeleton
        case .empty: EmptyState(title: "Your first post starts the story", line: "Every workout you complete lands here.", ctaTitle: "Go to today", action: onGoHome) // W6: the CTA is the day, not a composer
        case .failed(let line): ErrorState(line: line) { load() }
        case .ready, .offline: content
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
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Text("Did I show up?").font(.headline).foregroundStyle(EmberColors.inkText)
                HeatMapView(days: model.heatMap, todayKey: model.todayKey, selected: selected?.dayKey) { selected = model.select($0) }
                if let selected { dayCard(selected) }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: EmberTokens.Spacing.space12) {
                        ForEach(model.weeks) { week in
                            VStack {
                                WeeklyRing(done: week.done, planned: week.planned)
                                Text(DayLabel.weekHeader(week.weekKey, todayWeekKey: DayKey.weekKey(for: model.todayKey))).font(.caption).foregroundStyle(EmberColors.secondaryText)
                            }
                        }
                    }
                }
                Text("Streak \(model.totals.currentStreak) · longest \(model.totals.longestStreak) · \(model.totals.workouts) workouts · \(model.totals.posts) posts").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                Text("How much work?").font(.headline).foregroundStyle(EmberColors.inkText)
                Text("Sets per week: \(model.weeks.map { String($0.sets) }.joined(separator: " · "))").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                Text(balanceLine).font(.footnote).foregroundStyle(EmberColors.secondaryText)
                if let movementLine { Text(movementLine).font(.footnote).foregroundStyle(EmberColors.secondaryText) }
                if !model.strength.isEmpty {
                    Text("Am I stronger?").font(.headline).foregroundStyle(EmberColors.inkText)
                    ForEach(model.strength) { ExerciseChartView(trend: $0, units: units) }
                }
            }
            .padding(EmberTokens.Spacing.space16)
        }
    }

    // SPEC: Flow 9 layer 2 — "Push N · Pull N · Legs N" (+ " · Full body N" when legacy full-body sessions exist)
    private var balanceLine: String {
        let base = "Push \(model.balance.push) · Pull \(model.balance.pull) · Legs \(model.balance.legs)"
        return model.balance.fullBody > 0 ? "\(base) · Full body \(model.balance.fullBody)" : base
    }

    // SPEC: A2 — "Cardio N min · Mobility M min this week": facts, never targets; nothing at all when both are zero (A8)
    private var movementLine: String? {
        guard let week = model.weeks.last, week.cardioMinutes > 0 || week.mobilityMinutes > 0 else { return nil }
        return "Cardio \(week.cardioMinutes) min · Mobility \(week.mobilityMinutes) min this week"
    }

    // SPEC: Flow 9 layer 1 — the day card: its DayLabel (A6), that day's workouts
    private func dayCard(_ detail: DayDetail) -> some View {
        Card {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                Text(DayLabel.dayLabel(detail.dayKey, todayKey: model.todayKey)).font(.subheadline.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                ForEach(detail.workouts, id: \.self) { Text($0).foregroundStyle(EmberColors.inkText) }
                if detail.workouts.isEmpty { Text("Nothing that day. Tomorrow's a fresh one.").foregroundStyle(EmberColors.secondaryText) }
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
