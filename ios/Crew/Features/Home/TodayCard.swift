// SPEC: Flow 2 (today's card: "PUSH DAY · 5 exercises + mobility") · Flow 5 (rest day copy) · Flow 7 (paused 🧊) · 1D (the
// bridge CTA replaces the layout) · Part III law ① (the card's CTA is ink). Branches only on view state (5.6.6).
// WRITTEN — UNVERIFIED (needs Mac). T024

import SwiftUI

struct TodayCard: View {
    let state: TodayState
    let onStart: () -> Void
    let onPost: () -> Void

    var body: some View {
        switch state {
        case .bridge(let kind):
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Text("Your first flame lights today.").font(.headline).foregroundStyle(EmberColors.secondaryText)
                PrimaryButton(title: kind == .workout ? "Start your first workout" : "Start your streak — post a meal", action: kind == .workout ? onStart : onPost)
            }
        case .workout(let name, let exerciseCount, _):
            Card {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                    Text(name.uppercased()).font(.caption.weight(.semibold)).foregroundStyle(EmberColors.secondaryText)
                    Text("\(exerciseCount) exercises + mobility").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                    PrimaryButton(title: "Start workout", action: onStart)
                }
            }
        case .rest(let posted):
            Card {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                    Text("Rest day — recovery is part of the plan.").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                    Text(posted ? "Today's posted. Streak safe." : "Post something today and the streak stays safe.").font(.body).foregroundStyle(EmberColors.secondaryText)
                    if !posted { SecondaryButton(title: "Post a meal", action: onPost) }
                }
            }
        case .paused(let until):
            Card {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                    Text("Plan paused").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                    Text("Your streak is frozen until \(until). Reminders are off.").font(.body).foregroundStyle(EmberColors.secondaryText)
                }
            }
        case .allDone:
            Card {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space12) {
                    Text("Done for today.").font(.title3.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                    Text("Post a plate whenever. Bonus workouts are always welcome.").font(.body).foregroundStyle(EmberColors.secondaryText)
                }
            }
        }
    }
}
