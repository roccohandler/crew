// SPEC: S10 Complete → Post as amended by A28 (b), (c), (d) (owner-approved 2026-09-19; design/targets 11) — the celebration screen
// type: a full-bleed centred stack, no nav. The flame in accent beside the streak numeral in INK; the phrase; the XP numeral and its
// unit in ACCENT (the one orange text, at large-text sizes — R-083 (3)); the day in the journal's own sentence with NO minutes
// ("Push day · 6 of 6 sets", A28 (c)); then "Share to crew" (the one filled button) over "Keep it private" as text. Accent budget:
// three (flame, XP numeral, XP unit). GAP 9 read conservatively (R-085): the phrase is S10's own "Counted.", and the badges stay
// here as ink lines — words, no emoji, no confetti (A28 (b): a PR is stated in ink). Kept: numbers match the engine exactly; ≤ 2.5 s,
// skippable on the first tap, static under Reduce Motion (6.4); A21.9 — no post exists until a button is tapped; solo sees Done
// (Flow 10); the sheet cannot be swiped away (HomeScreen). WRITTEN — UNVERIFIED (needs Mac). T026 · R2

import SwiftUI

struct CelebrationScreen: View {
    let outcome: CelebrationOutcome
    let onChoose: (_ shareToCrew: Bool) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownXP = 0
    @State private var chosen = false // one answer per celebration, however fast the thumb
    @ScaledMetric(relativeTo: .largeTitle) private var flameSize: CGFloat = EmberTokens.Focus.flameCelebration
    private var hasCrew: Bool { (try? Store.shared.crewSnapshot()) != nil }
    @MainActor private var session: LocalSession? { try? Store.shared.session(clientId: outcome.postDraft.sessionClientId) }

    private var xpTotal: Int { outcome.awards.reduce(0) { total, award in if case .xp(let amount, _) = award { return total + amount } else { return total } } }

    // The streak this workout leaves: the engine's new value when the day moved it, else what the phone already holds
    @MainActor private var streak: Int {
        if let moved = outcome.awards.compactMap({ if case .streakTo(let value) = $0 { return value } else { return nil } }).last { return moved }
        return session.flatMap { try? Store.shared.gamificationState(for: $0.userId).currentStreak } ?? 0
    }

    // SPEC: A6 · A28 (c) — "Push day · 6 of 6 sets" (+ " + Walk 25 min" for a done cardio block — GAP 4, R-084 (2)); a cardio log
    // reads "Walk · 25 min · 2.1 km"
    @MainActor private var summaryLine: String {
        guard let session else { return "\(outcome.setsDone) of \(outcome.setsPlanned) sets" }
        if session.workoutKind == "cardio" { return JournalFacts.summaryLine(session, distanceUnit: AuthStore.shared.distanceUnit) }
        return SessionSummaryLine.sessionSummaryLine(workoutName: session.workoutName, isCardio: false, setsDone: outcome.setsDone, setsPlanned: outcome.setsPlanned, cardioMinutes: nil, distanceMeters: nil, distanceUnit: AuthStore.shared.distanceUnit) + JournalFacts.cardioSuffix(session)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: EmberTokens.Spacing.space32)
            VStack(spacing: EmberTokens.Spacing.space16) {
                HStack(alignment: .center, spacing: EmberTokens.Spacing.space12) {
                    Image(systemName: streak > 0 ? "flame.fill" : "flame").font(.system(size: flameSize, weight: .semibold))
                        .foregroundStyle(streak > 0 ? EmberColors.accent : EmberColors.inkMuted)
                    Text("\(streak)").typeRole(EmberTokens.Typography.celebrationNumeral).foregroundStyle(EmberColors.ink)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Streak \(streak)")
                Text("Counted.").typeRole(EmberTokens.Typography.celebrationPhrase).foregroundStyle(EmberColors.ink) // S10 · GAP 9
                HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Focus.space6) {
                    Text("+\(shownXP)").typeRole(EmberTokens.Typography.ringNumeral).contentTransition(.numericText())
                    Text("XP").typeRole(EmberTokens.Typography.xpUnit)
                }
                .foregroundStyle(EmberColors.accent)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Plus \(xpTotal) XP")
                Text(numerals: summaryLine).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                ForEach(Array(badges.enumerated()), id: \.offset) { _, line in
                    Text(line).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink).multilineTextAlignment(.center)
                }
            }
            Spacer(minLength: EmberTokens.Spacing.space32)
            VStack(spacing: EmberTokens.Spacing.space4) {
                if hasCrew {
                    PrimaryButton(title: "Share to crew") { choose(true) }
                    TextActionButton(title: "Keep it private", role: EmberTokens.Typography.textButton) { choose(false) }
                } else {
                    PrimaryButton(title: "Done") { choose(false) } // Flow 10: solo skips share — the post goes to the private journal
                }
            }
        }
        .padding(.horizontal, EmberTokens.Focus.gutter)
        .padding(.bottom, EmberTokens.Spacing.space12)
        .frame(maxWidth: .infinity)
        .background(EmberColors.canvas.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { shownXP = xpTotal } // skippable on first tap
        .onAppear { countUp() }
    }

    private func choose(_ shareToCrew: Bool) {
        guard !chosen else { return }
        chosen = true
        onChoose(shareToCrew)
    }

    // A28 (b) · R-083 (12) — the milestones in ink and in words: no 🎉, no 🛡, no confetti
    private var badges: [String] {
        outcome.awards.compactMap { award in
            switch award {
            case .comeback: return "Comeback"
            case .perfectWeek: return "Perfect week — shield earned"
            case .shieldEarned: return nil
            case .levelUp(let level): return "Level \(level)"
            case .prBadge(let exercise): return "\(exercise): new best"
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
