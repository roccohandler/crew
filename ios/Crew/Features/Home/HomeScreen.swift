// SPEC: S07 Home as amended by A28 (d), (e) (owner-approved 2026-09-19; design/targets 01–06) — the Focus Card: the reward block
// (ring + flame; none on the first day or with no plan) over ONE card with at most one filled primary, then the quiet rows — "Quick
// complete" as text on a training day, "Edit today's log" as text on a done day, and the "Macros · N logged" fact row (training,
// rest and done days; absent under 18, A22 G4). Cardio and a bonus workout live behind the "+" in the nav bar. No nav title (the
// card's names the state), no week strip, no verb rows, no crew strip (A28 (d) removes it; A20.6 never landed). Kept: the BRIDGE
// until the first post (1D); today-state < 500 ms warm; Quick Complete hidden once today counts; A21.9's two celebration buttons
// and the post that follows the tap; A21.4's reminder opt-in after the first workout, once. Screens hold ZERO logic (5.6.6).
// WRITTEN — UNVERIFIED (needs Mac). T024 · R1

import SwiftUI

struct HomeScreen: View {
    var onOpenJournal: () -> Void = {} // A28 (d) · R-083 (18): "Edit today's log" opens today in the Journal, with the powers it already has
    @State private var model = HomeModel(welcomeBackAckDay: AuthStore.shared.currentUser?.welcomeBackAckDay) // E4: the account remembers the answer (as ProgressScreen and SettingsScreen read units)
    @State private var loaded = false
    @State private var activeSession: LocalSession?
    @State private var celebration: CelebrationOutcome?
    @State private var rebuilding = false
    @State private var choosingBonus = false
    @State private var loggingCardio = false
    @State private var loggingMacros = false // A22 G4: the Macros fact row opens nutrition Today
    @State private var adding = false        // A28 (d): the "+" sheet
    @State private var addChoice: HomeAddChoice?
    @State private var offerReminder = false // A21.4: decided when a celebration is answered, presented once the sheet is down
    @State private var showsReminder = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            Group {
                switch loadState {
                case .loading: syncing
                case .ready, .offline: content
                case .empty: centred { NoPlanCard(weekday: model.weekdayName) { rebuilding = true } }
                case .failed(let line): ErrorState(line: line) { Task { await ServerHydrate.pullIfEmpty(userId: model.userId, store: model.store) }; load() } // an unreached plan pulls again
                }
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(EmberColors.canvas, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { addButton } }
            .navigationDestination(item: $activeSession) { session in SessionScreen(session: session) { outcome in activeSession = nil; celebration = outcome; model.refresh() } }
            .navigationDestination(isPresented: $loggingCardio) { CardioLogScreen { outcome in loggingCardio = false; celebration = outcome; model.refresh() } } // A2: then the normal celebration
            .navigationDestination(isPresented: $loggingMacros) { NutritionTodayScreen() } // nutrition addendum Q3: the Home row is the way in
            .onChange(of: loggingMacros) { _, open in if !open { model.refresh() } } // back from Today: the row's count may have moved
            // SPEC: A21.9 — no swipe-to-dismiss: a celebration is answered by one of its two buttons or not at all; the tapped
            // button posts (answerCelebration), then the sheet comes down, then — after the first workout — the reminder opt-in (A21.4)
            .sheet(item: $celebration, onDismiss: { if offerReminder { offerReminder = false; showsReminder = true } }) { outcome in
                CelebrationScreen(outcome: outcome) { share in model.answerCelebration(outcome, shareToCrew: share); offerReminder = model.shouldOfferReminder(); celebration = nil }
                    .interactiveDismissDisabled()
            }
            .sheet(isPresented: $showsReminder) { ReminderOptInSheet(userId: model.userId, storedReminderTime: AuthStore.shared.currentUser?.reminderTime) { showsReminder = false } }
            .sheet(isPresented: $rebuilding) { OnboardingFlow(mode: .rebuild) { rebuilding = false; load() } }
            .sheet(isPresented: $choosingBonus) { BonusWorkoutSheet(workouts: model.bonusWorkouts) { workout in choosingBonus = false; activeSession = model.startBonus(workout) } }
            // the choice is carried out once the "+" sheet is down, so a push or a second sheet never races the first one's dismissal
            .sheet(isPresented: $adding, onDismiss: runAddChoice) { HomeAddSheet(offersBonus: offersBonus) { choice in addChoice = choice; adding = false } }
            .task { model.postUnanswered(); load() } // A21.9: a celebration the app died under posts privately first
            .onChange(of: scenePhase) { _, phase in if phase == .active, loaded { load() } } // E8/V04: elapsed days are judged on every foreground
            .onChange(of: ServerHydrate.state.revision) { _, _ in load() } // 2026-09-18: each piece of the reinstall pull lands → the real screen fills
            .modifier(EdgePrompts(model: model, onKeepGoing: { activeSession = model.keepGoingWithStaleSession() }, onRebuild: { rebuilding = true }))
        }
    }

    // SPEC: A28 (d) — the reward block and the card, optically centred, with the quiet rows beneath (6.7 as amended: Home's primary
    // sits in the card; the screen still scrolls when Dynamic Type makes the day taller than the phone).
    private var content: some View {
        centred {
            // A20.9 — the banner states the two facts the queue publishes (a legacy surface until the states are redrawn, debt.md)
            if loadState == .offline {
                OfflineBanner(lastSyncedLine: "Showing what you had — syncing when you're back.", pending: model.pendingToSend, lastSyncedAt: model.lastSyncedAt)
                    .padding(.bottom, EmberTokens.Spacing.space16)
            }
            if !isBridge {
                HomeRewardBlock(streak: model.streak, shields: model.shields, ringDone: model.ringDone, ringPlanned: model.ringPlanned, isPaused: isPaused)
                    .padding(.bottom, EmberTokens.Focus.rewardToCard)
            }
            TodayCard(state: model.today,
                      weekday: model.weekdayName,
                      work: model.cardWork,
                      nextUp: model.nextUp,
                      todaySummaryLines: model.todaySummaryLines,
                      pausedUntil: model.pausedUntilLong,
                      resuming: model.resumeSession != nil,
                      onStart: { activeSession = model.startWorkout() },
                      onBonus: { choosingBonus = true }, // A22 / R-070: the rest-day bridge's one control is the bonus workout
                      onEndPause: { Task { await model.endPause() } })
            quietRows.padding(.top, EmberTokens.Spacing.space16)
        }
    }

    @ViewBuilder
    private var quietRows: some View {
        VStack(spacing: EmberTokens.Spacing.space8) {
            if model.quickCompleteAvailable, !isBridge {
                TextActionButton(title: "Quick complete", role: EmberTokens.Typography.textButton) { celebration = model.quickComplete() }
                Whisper(.howQuickComplete) // A23
            }
            if case .allDone = model.today { TextActionButton(title: "Edit today's log", role: EmberTokens.Typography.textButton, action: onOpenJournal) }
            if isPaused, let session = model.resumeSession { TextActionButton(title: "Resume workout", role: EmberTokens.Typography.textButton) { activeSession = session } }
            if showsMacros, let macros = model.vectors.macros { macrosRow(macros) }
        }
    }

    // SPEC: A28 (d) — "Macros · 2 logged" / "Macros · nothing logged yet"; the count alone is rounded (§4). A22 G4: absent under 18
    private func macrosRow(_ macros: MacrosSlot) -> some View {
        let text: Text = macros.logged.map { Text("Macros · ") + Text("\($0)").fontDesign(.rounded) + Text(" logged") } ?? Text("Macros · nothing logged yet")
        let label = macros.logged.map { "Macros, \($0) logged today" } ?? "Macros, nothing logged yet"
        return QuietFactRow(text: text, accessibilityLabel: label) { loggingMacros = true }
    }

    // SPEC: A28 (d) — the "+" icon button: 44 × 44, an ink glyph, always an accessibility label (system §8)
    private var addButton: some View {
        Button { adding = true } label: {
            Image(systemName: "plus").foregroundStyle(EmberColors.ink)
                .frame(minWidth: CGFloat(SpecConstants.minTouchTargetPt), minHeight: CGFloat(SpecConstants.minTouchTargetPt))
        }
        .accessibilityLabel(offersBonus ? "Log cardio or a bonus workout" : "Log cardio")
        .accessibilityIdentifier("home.add")
    }

    // SPEC: 6.1 as amended 2026-09-18 ("launch: real UI first") — the reinstall wait is Home's OWN chrome: the reward block as it stands
    // and one card saying what is arriving, never a skeleton; each landed pull re-reads the Store and the card gives way to the day.
    private var syncing: some View {
        centred {
            HomeRewardBlock(streak: model.streak, shields: model.shields, ringDone: model.ringDone, ringPlanned: model.ringPlanned, isPaused: false)
                .padding(.bottom, EmberTokens.Focus.rewardToCard)
            FocusCard { LoadingLine(line: "Syncing your week from your account…") }
        }
    }

    // One column in the 20 pt gutter, centred in the height the phone has, scrolling when the content is taller (6.7)
    private func centred<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: EmberTokens.Focus.gutter)
                    content()
                    Spacer(minLength: EmberTokens.Focus.gutter)
                }
                .padding(.horizontal, EmberTokens.Focus.gutter)
                .frame(minHeight: proxy.size.height)
            }
        }
    }

    private func runAddChoice() {
        guard let choice = addChoice else { return }
        addChoice = nil
        switch choice {
        case .cardio: loggingCardio = true
        case .bonus: choosingBonus = true
        }
    }

    // A3 / Flow 5 — a bonus workout on a rest day or a done day (and off-season, where it is reachable and pays nothing, V79)
    private var offersBonus: Bool {
        switch model.today {
        case .rest, .allDone, .paused: return model.hasPlan
        case .bridge, .workout: return false
        }
    }

    private var showsMacros: Bool {
        switch model.today {
        case .workout, .rest, .allDone: return true
        case .bridge, .paused: return false
        }
    }

    private var isPaused: Bool { if case .paused = model.today { return true } else { return false } }
    private var isBridge: Bool { if case .bridge = model.today { return true } else { return false } } // 1D: no reward block on the first day

    // A18.12 / A20.9 — computed over the @Observable model, never stored (the class of bug A20.9 removed)
    private var loadState: HomeLoadState {
        guard loaded else { return .loading }
        return HomeLoadState.of(loadError: model.loadError, hasPlan: model.hasPlan, offline: model.offline, syncing: ServerHydrate.state.isPulling, unreachable: ServerHydrate.state.failedOffline)
    }

    private func load() {
        model.refresh()
        loaded = true
        Signposts.endLaunchIfNeeded() // 8.8: launch → Home interval closes on the first real state
    }
}

// LocalSession is Identifiable + Hashable through PersistentModel (SwiftData) — no extension, or the conformance is redundant
extension CelebrationOutcome: Identifiable {
    var id: String { postDraft.clientId }
}
