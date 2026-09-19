// SPEC: A28 (a) — the chrome UIKit draws for SwiftUI (navigation titles, the tab bar's items and surface) takes the table's colours:
// ink, never the platform's black (R0's review found every title and unselected tab black — "Ink is navy, not charcoal", 1.4), the
// tab bar on `tabBar` with a `hairlineOnCanvas` rule, and bars without glass blur (system §11) — an opaque canvas bar once content
// scrolls under it, a transparent one at rest. Set once at launch; the colours are the adaptive EmberColors, so dark follows.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI
import UIKit

enum Chrome {
    @MainActor
    static func apply() {
        let ink = UIColor(EmberColors.ink)
        let secondary = UIColor(EmberColors.inkSecondary)

        let scrolled = UINavigationBarAppearance()
        scrolled.configureWithOpaqueBackground()
        scrolled.backgroundColor = UIColor(EmberColors.canvas)
        scrolled.shadowColor = UIColor(EmberColors.hairlineOnCanvas)
        let resting = UINavigationBarAppearance()
        resting.configureWithTransparentBackground()
        for appearance in [scrolled, resting] {
            appearance.titleTextAttributes = [.foregroundColor: ink]
            appearance.largeTitleTextAttributes = [.foregroundColor: ink]
        }
        let navigation = UINavigationBar.appearance()
        navigation.standardAppearance = scrolled
        navigation.compactAppearance = scrolled
        navigation.scrollEdgeAppearance = resting
        navigation.tintColor = ink

        let tabs = UITabBarAppearance()
        tabs.configureWithOpaqueBackground()
        tabs.backgroundColor = UIColor(EmberColors.tabBar)
        tabs.shadowColor = UIColor(EmberColors.hairlineOnCanvas)
        for layout in [tabs.stackedLayoutAppearance, tabs.inlineLayoutAppearance, tabs.compactInlineLayoutAppearance] {
            layout.normal.iconColor = secondary
            layout.normal.titleTextAttributes = [.foregroundColor: secondary]
            layout.selected.iconColor = ink
            layout.selected.titleTextAttributes = [.foregroundColor: ink]
        }
        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabs
        tabBar.scrollEdgeAppearance = tabs
        tabBar.tintColor = ink
        tabBar.unselectedItemTintColor = secondary

        // the Logger's number alert and every confirm are UIKit's: their caret and their plain buttons take ink, never the system's
        // blue (ui-reviewer, run 35444308817). A destructive button keeps the platform's red, the one place red appears (A28 (a)).
        UITextField.appearance().tintColor = ink
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = ink
    }
}
