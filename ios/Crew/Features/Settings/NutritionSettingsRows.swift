// SPEC: nutrition addendum §4 ("Settings gains three rows": Nutrition targets · How targets are estimated (A16.a) · Delete my
// nutrition data — two-step, "can't be undone": targets + bodyweight + saved meals + template + logs in one cascade) · §6: under 18
// the rows are ABSENT, with no copy — SettingsScreen renders this section only when the surface exists. An account with no birth year
// is asked for it where Nutrition opens, so its targets row leads there. E18: the one red thing in Settings stays Delete account, so
// this delete is ink. The delete is NETWORK-ONLY, like endPause (R-074 (8)): offline it fails and says so; once the server confirms,
// the phone's rows and any queued nutrition op go too (NutritionLocal.wipe). Screens hold ZERO logic beyond the two-step reveal.
// Twin of web components/nutrition/NutritionSettings.tsx. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct NutritionSettingsRows: View {
    let availability: NutritionAvailability
    @State private var confirming = false
    @State private var line: String?
    @State private var showsTargets = false
    @State private var showsMethod = false

    // A28 (f) · R-091: two cards on the gutter — the two pages as row buttons, then the two-step delete — not the platform's List
    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            FocusCard(padding: 0) {
                VStack(spacing: 0) {
                    RowButton(title: "Nutrition targets") { showsTargets = true }
                    cardSeam()
                    RowButton(title: "How targets are estimated") { showsMethod = true }
                }
            }
            // R-095: the two-step delete is the kit's text buttons on the gutter — alone in a card, one row read as a capsule, the
            // button shape, in a third button style
            VStack(alignment: .leading, spacing: 0) {
                if confirming {
                    Text("This deletes your targets, your bodyweight, your saved meals, your template and every logged meal. It can't be undone.").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: EmberTokens.Spacing.space24) {
                        TextActionButton(title: "Delete my nutrition data", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { Task { await erase() } }
                        TextActionButton(title: "Keep it", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { confirming = false }
                    }
                } else {
                    TextActionButton(title: "Delete my nutrition data", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { confirming = true; line = nil }
                }
            }
            if let line { Text(line).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary) }
        }
        // §6: an account with no birth year is asked for it where Nutrition opens, so its targets row leads there
        .navigationDestination(isPresented: $showsTargets) { if availability == .askBirthYear { NutritionTodayScreen() } else { NutritionTargetsScreen() } }
        .navigationDestination(isPresented: $showsMethod) { NutritionMethodScreen() }
    }

    @MainActor
    private func erase() async {
        do {
            _ = try await Api.shared.deleteNutritionData()
            try? NutritionLocal.wipe(userId: AuthStore.shared.currentUser?.id ?? "local", store: .shared)
            line = "Deleted."
        } catch let error as AppError {
            line = error.userLine
        } catch {
            line = AppError.invalidResponse.userLine
        }
        confirming = false
    }
}
