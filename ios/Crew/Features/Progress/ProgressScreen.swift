// SPEC: S15 Progress — LAYER 1 did I show up (heat map → day detail with workout + plates; rings history; streaks; totals;
// meals/week) · LAYER 2 how much work (sets/week, Push/Pull/Legs balance) · LAYER 3 am I stronger (only where weights were
// logged) · empty (new user) invites. WRITTEN — UNVERIFIED (needs Mac). T040

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
    private var units: String { AuthStore.shared.currentUser?.units ?? "lb" }

    var body: some View {
        NavigationStack {
            Group {
                switch loadState {
                case .loading: ListSkeleton()
                case .empty: EmptyState(title: "Your first post starts the story", line: "Every workout and every plate lands here.", ctaTitle: "Post something") {}
                case .failed(let line): ErrorState(line: line) { load() }
                case .ready, .offline: content
                }
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Progress")
            .toolbar { ToolbarItem(placement: .primaryAction) { Button("Journal") { showsJournal = true } } }
            .navigationDestination(isPresented: $showsJournal) { JournalScreen(posts: (try? Store.shared.allPosts(for: AuthStore.shared.currentUser?.id ?? "local")) ?? []) { post in post.deletedAt = Date(); try? Store.shared.save(); try? SyncQueue.shared.enqueue(.deletePost, payload: ["clientId": post.clientId]); load() } }
            .task { load() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Text("Did I show up?").font(.headline).foregroundStyle(EmberColors.inkText)
                HeatMapView(days: model.heatMap, selected: selected?.dayKey) { selected = model.select($0) }
                if let selected {
                    Card {
                        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                            Text(selected.dayKey).font(.subheadline.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                            ForEach(selected.workouts, id: \.self) { Text($0).foregroundStyle(EmberColors.inkText) }
                            ForEach(selected.plates, id: \.clientId) { Text($0.caption.isEmpty ? (MealTag(rawValue: $0.mealTag ?? "")?.emoji ?? "🍽") : $0.caption).foregroundStyle(EmberColors.secondaryText) }
                            if selected.workouts.isEmpty && selected.plates.isEmpty { Text("Nothing that day. Tomorrow's a fresh one.").foregroundStyle(EmberColors.secondaryText) }
                        }
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: EmberTokens.Spacing.space12) { ForEach(model.weeks) { week in VStack { WeeklyRing(done: week.done, planned: week.planned, days: []); Text(String(week.weekKey.dropFirst("YYYY-".count))).font(.caption).foregroundStyle(EmberColors.secondaryText) } } }
                }
                Text("Streak \(model.totals.currentStreak) · longest \(model.totals.longestStreak) · \(model.totals.workouts) workouts · \(model.totals.posts) posts · \(model.weeks.last?.meals ?? 0) meals this week").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                Text("How much work?").font(.headline).foregroundStyle(EmberColors.inkText)
                Text("Sets per week: \(model.weeks.map { String($0.sets) }.joined(separator: " · "))").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                Text("Push \(model.balance.push) · Pull \(model.balance.pull) · Legs \(model.balance.legs)").font(.footnote).foregroundStyle(EmberColors.secondaryText)
                if !model.strength.isEmpty {
                    Text("Am I stronger?").font(.headline).foregroundStyle(EmberColors.inkText)
                    ForEach(model.strength) { ExerciseChartView(trend: $0, units: units) }
                }
            }
            .padding(EmberTokens.Spacing.space16)
        }
    }

    private func load() {
        model.refresh()
        loadState = model.isEmpty ? .empty : .ready
    }
}
