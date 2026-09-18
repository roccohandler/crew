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

    var body: some View {
        Section("Nutrition") {
            if availability == .askBirthYear {
                NavigationLink("Nutrition targets") { NutritionTodayScreen() } // §6: the birth year is asked where Nutrition opens
            } else {
                NavigationLink("Nutrition targets") { NutritionTargetsScreen() }
            }
            NavigationLink("How targets are estimated") { NutritionMethodScreen() }
            if confirming {
                Text("This deletes your targets, your bodyweight, your saved meals, your template and every logged meal. It can't be undone.").font(.footnote).foregroundStyle(EmberColors.inkText)
                Button("Delete my nutrition data") { Task { await erase() } }.foregroundStyle(EmberColors.inkText)
                Button("Keep it") { confirming = false }.foregroundStyle(EmberColors.inkText)
            } else {
                Button("Delete my nutrition data") { confirming = true; line = nil }.foregroundStyle(EmberColors.inkText)
            }
            if let line { Text(line).font(.footnote).foregroundStyle(EmberColors.secondaryText) }
        }
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
