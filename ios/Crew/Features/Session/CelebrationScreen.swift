// SPEC: S10 Complete → Post — numbers match the engine exactly; celebration ≤ 2.5 s, skippable on first tap, haptic-only;
// share-default remembered; solo skips share; PR badge only where weights logged; level-ups fold in (E8). Flow 2 "THE MOMENT":
// 18/18 sets · 44 min · +125 XP counts in · streak ticks 12 → 13. Part III law ④: the ember appears because progress happened.
// A2 (owner-directed 2026-09-08): "+ Walk 25 min" appended when a cardio block was done; a standalone cardio log reads its
// A6 line. "Counted." sits above the share choice. WRITTEN — UNVERIFIED (needs Mac). T026

import SwiftUI

struct CelebrationScreen: View {
    let outcome: CelebrationOutcome
    let onDone: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownXP = 0
    @AppStorage("shareToCrewDefault") private var shareDefault = true
    private var hasCrew: Bool { (try? Store.shared.crewSnapshot()) != nil }
    @MainActor private var session: LocalSession? { try? Store.shared.session(clientId: outcome.postDraft.sessionClientId) }
    private var units: String { AuthStore.shared.currentUser?.units ?? "lb" }

    private var xpTotal: Int { outcome.awards.reduce(0) { total, award in if case .xp(let amount, _) = award { return total + amount } else { return total } } }
    private var newStreak: Int? { outcome.awards.compactMap { if case .streakTo(let value) = $0 { return value } else { return nil } }.last }

    // SPEC: S10 · A6 — "12/12 sets · 44 min" with the server's rounding of minutes; A2 — "+ Walk 25 min" when a cardio block
    // was done; a session of kind cardio reads "Walk · 25 min · 2.1 km"
    @MainActor private var summaryLine: String {
        if let session, session.workoutKind == "cardio" { return JournalFacts.summaryLine(session, units: units) }
        let minutes = JournalFacts.minutes(ofSeconds: outcome.durationSeconds)
        return "\(outcome.setsDone)/\(outcome.setsPlanned) sets · \(minutes) min\(session.map { JournalFacts.cardioSuffix($0) } ?? "")"
    }

    var body: some View {
        VStack(spacing: EmberTokens.Spacing.space24) {
            Spacer()
            Text(summaryLine).font(.title3).foregroundStyle(EmberColors.secondaryText).multilineTextAlignment(.center)
            Text("+\(shownXP) XP").font(.largeTitle.weight(.bold).monospacedDigit()).foregroundStyle(EmberColors.emberText).contentTransition(.numericText())
            if let newStreak { StreakFlame(streak: newStreak, paused: false) }
            ForEach(Array(badges.enumerated()), id: \.offset) { _, line in Text(line).font(.headline).foregroundStyle(EmberColors.emberText) }
            Spacer()
            Text("Counted.").font(.headline).foregroundStyle(EmberColors.inkText) // S10: the fact, then the choice
            if hasCrew {
                Toggle("Share to crew", isOn: $shareDefault).tint(EmberColors.inkText).font(.body).foregroundStyle(EmberColors.inkText)
                PrimaryButton(title: shareDefault ? "Share to crew" : "Done", action: onDone)
            } else {
                PrimaryButton(title: "Done", action: onDone) // Flow 10: solo skips share
            }
        }
        .padding(EmberTokens.Spacing.space24)
        .background(EmberColors.canvas.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { shownXP = xpTotal } // skippable on first tap
        .onAppear { countUp() }
    }

    private var badges: [String] {
        outcome.awards.compactMap { award in
            switch award {
            case .comeback: return "Comeback 🎉"
            case .perfectWeek: return "Perfect week — shield earned 🛡"
            case .shieldEarned: return nil
            case .levelUp(let level): return "Level \(level)"
            case .prBadge(let exercise): return "\(exercise): new best 🎉"
            case .achievement(let id): return SeedCatalog.shared.achievements.first { $0.id == id }?.title
            default: return nil
            }
        }
    }

    // ≤ 2.5 s count-up; static under Reduce Motion (6.4)
    private func countUp() {
        guard !reduceMotion, xpTotal > 0 else { shownXP = xpTotal; return }
        let steps = min(xpTotal, SpecConstants.xpFirstPostOfDay)
        let interval = SpecConstants.celebrationMaxSeconds / Double(steps)
        for step in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(step)) {
                withAnimation(.crewSpring) { shownXP = xpTotal * step / steps }
            }
        }
    }
}
