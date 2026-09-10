// SPEC: S15 Progress — LAYER 1 did I show up (heat map → day detail with workout + plates; rings history; streaks; totals;
// meals/week) · LAYER 2 how much work (sets/week, Push/Pull/Legs balance, cardio and mobility minutes — A2) · LAYER 3 am I
// stronger (only where weights were logged) · empty (new user) invites and its CTA posts. A6: week captions and the day card
// read the DayLabel twin. 6.1: a Store error is the failed state with Try again. WRITTEN — UNVERIFIED (needs Mac). T040

import SwiftUI

enum ProgressLoadState: Equatable {
    case loading
    case ready
    case empty
    case failed(String)
    case offline
}

struct ProgressScreen: View {
    @State private var model = ProgressModel()
    @State private var loadState: ProgressLoadState = .loading
    @State private var selected: DayDetail?
    @State private var showsJournal = false
    @State private var posting = false
    private var units: String { AuthStore.shared.weightUnit } // A9
    private var userId: String { AuthStore.shared.currentUser?.id ?? "local" }

    var body: some View {
        NavigationStack {
            Group {
                switch loadState {
                case .loading: ListSkeleton()
                case .empty: EmptyState(title: "Your first post starts the story", line: "Every workout and every plate lands here.", ctaTitle: "Post something") { posting = true }
                case .failed(let line): ErrorState(line: line) { load() }
                case .ready, .offline: content
                }
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Progress")
            .toolbar { ToolbarItem(placement: .primaryAction) { Button("Journal") { showsJournal = true } } }
            .navigationDestination(isPresented: $showsJournal) { journal }
            .sheet(isPresented: $posting) { NutritionPostScreen { posting = false; load() } }
            .task { load() }
        }
    }

    // SPEC: A6 — the journal reads the Store each time it is built: every post, plus the plan's training days (A1) for rest-day labels
    private var journal: some View {
        JournalScreen(posts: (try? Store.shared.allPosts(for: userId)) ?? [], trainingWeekdays: (try? Store.shared.plan(for: userId))?.trainingWeekdays ?? [], distanceUnit: AuthStore.shared.distanceUnit, onDelete: { post in
            post.deletedAt = Date()
            try? Store.shared.save()
            try? SyncQueue.shared.enqueue(.deletePost, payload: ["clientId": post.clientId])
            load()
        }, onPosted: { load() })
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
                Text("Streak \(model.totals.currentStreak) · longest \(model.totals.longestStreak) · \(model.totals.workouts) workouts · \(model.totals.posts) posts · \(model.weeks.last?.meals ?? 0) meals this week").font(.footnote).foregroundStyle(EmberColors.secondaryText)
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

    // SPEC: Flow 9 layer 1 — the day card: its DayLabel (A6), that day's workouts and plates
    private func dayCard(_ detail: DayDetail) -> some View {
        Card {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                Text(DayLabel.dayLabel(detail.dayKey, todayKey: model.todayKey)).font(.subheadline.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                ForEach(detail.workouts, id: \.self) { Text($0).foregroundStyle(EmberColors.inkText) }
                ForEach(detail.plates, id: \.clientId) { Text($0.caption.isEmpty ? (MealTag(rawValue: $0.mealTag ?? "")?.emoji ?? "🍽") : $0.caption).foregroundStyle(EmberColors.secondaryText) }
                if detail.workouts.isEmpty && detail.plates.isEmpty { Text("Nothing that day. Tomorrow's a fresh one.").foregroundStyle(EmberColors.secondaryText) }
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
