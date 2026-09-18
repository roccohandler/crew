// SPEC: nutrition addendum §4 (Today) · §6 (the 18+ gate) · Q3 (the Home row "Log macros" is the way in) · 6.9 Screen Density (A25 —
// pass/fail) — three states of one screen: an account with no birth year is asked for it ONCE, here (never at launch); with no targets
// yet it is the first-run state (one number → the estimate); otherwise Today, which has ONE job — the four lines and "Your template",
// where one tap logs a slot. Quick add and today's log are each ONE TAP AWAY behind a labelled outline button, on their own screens
// (all of it on one screen ran past two scroll-lengths; 6.9 makes that a destination — R-077), and the text link leads to Saved meals
// & template. Today carries NO ink-filled primary of its own. An error is said in INK: the semantic red does not exist on a
// nutrition surface, and neither does ember (law ⑥'s exception). Screens hold ZERO logic (5.6.6): NutritionTodayModel decides.
// Twin of web nutrition/page.tsx + NutritionToday.tsx + BirthYearAsk.tsx. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct NutritionTodayScreen: View {
    @State private var model = NutritionTodayModel()
    @State private var bodyweightText = ""
    @State private var birthYearText = ""
    @State private var showsQuickAdd = false
    @State private var showsLog = false
    @FocusState private var focused: String?

    // 6.3 · 6.7 (DESIGN.md 4.2) — the two asking states carry one primary, bottom-anchored; Today itself has none, and a screen with no
    // primary gets no bar (BottomBar.swift: "it is conditional, and that is a rule")
    var body: some View {
        Group {
            switch model.availability {
            case .askBirthYear:
                page.crewBottomBar { PrimaryButton(title: "Continue", isLoading: model.isSaving) { focused = nil; Task { await model.saveBirthYear(birthYearText) } } }
            case .available where model.remaining == nil:
                page.crewBottomBar { PrimaryButton(title: "Estimate my targets") { focused = nil; model.estimate(bodyweightText: bodyweightText) } }
            default: page
            }
        }
    }

    private var page: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.sectionGap) {
                switch model.availability {
                case .absent: EmptyView() // A16.c: unreachable — the row that opens this screen does not exist under 18
                case .askBirthYear: birthYearAsk
                case .available: if let remaining = model.remaining { today(remaining) } else { firstRun }
                }
                if let error = model.errorLine { Text(error).font(.footnote.weight(.semibold)).foregroundStyle(EmberColors.inkText) }
            }
            .padding(EmberTokens.Spacing.space16)
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle(model.availability == .askBirthYear ? "Your birth year" : "Today")
        .navigationBarTitleDisplayMode(.inline)
        // A19.2 — a number pad carries no return key: one Done, on the trailing side, dismissing whichever field has focus
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = nil }
            }
        }
        .navigationDestination(isPresented: $showsQuickAdd) { QuickAddScreen(model: model) { showsQuickAdd = false } } // 6.9: one job, one tap away
        .navigationDestination(isPresented: $showsLog) { NutritionLogScreen(model: model) }
        .task { await model.open() }
        .onAppear { model.refresh() } // back from Saved meals & template: the template may have changed
    }

    @ViewBuilder
    private func today(_ remaining: MacroRemaining) -> some View {
        MacroLines(remaining: remaining)
        TemplateRows(slots: model.slots) { slot in
            Haptics.selection()
            model.tapSlot(slot)
        }
        VStack(spacing: EmberTokens.Spacing.rowGap) {
            SecondaryButton(title: "Quick add") { showsQuickAdd = true }
            // A8 — an empty day reports nothing: the button exists once there is something behind it
            if !model.logs.isEmpty { SecondaryButton(title: "Logged today · \(model.logs.count)") { showsLog = true } }
            NavigationLink { SavedMealsScreen() } label: {
                Text("Saved meals & template").font(.body.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                    .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
            }
        }
    }

    // SPEC: §3 — one number, one button, and the estimate does the rest; every number is the user's to overwrite afterwards
    private var firstRun: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            Text("Start with your bodyweight. It sets a first estimate of your protein, carbs and fat, and you can change any of it.").font(.body).foregroundStyle(EmberColors.secondaryText)
            NutritionTextField(title: "Bodyweight (\(model.weightUnit))", text: $bodyweightText, keyboard: .decimalPad, focus: $focused, key: "bodyweight")
            Text("Used for the estimate and nothing else. Only you can see it.").font(.footnote).foregroundStyle(EmberColors.secondaryText)
            NavigationLink("How targets are estimated") { NutritionMethodScreen() }.foregroundStyle(EmberColors.inkText)
        }
    }

    // SPEC: A16.c · §6 — asked once, with signup's own bounds; the year is stored on the server and never shown again
    private var birthYearAsk: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            Text("Nutrition needs it once. It's never shown to anyone.").font(.body).foregroundStyle(EmberColors.secondaryText)
            NutritionTextField(title: "Birth year", text: $birthYearText, keyboard: .numberPad, focus: $focused, key: "birthYear")
        }
    }
}

// The one labelled text field the nutrition screens share (a bodyweight, a birth year, a meal's name, a slot's label)
struct NutritionTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var focus: FocusState<String?>.Binding
    let key: String

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
            Text(title).font(.subheadline).foregroundStyle(EmberColors.inkText)
            TextField(title, text: $text)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .focused(focus, equals: key)
                .padding(EmberTokens.Spacing.space12)
                .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                .background(EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous).stroke(EmberColors.controlOutline, lineWidth: EmberTokens.Size.hairline)) // A18.11
                .accessibilityLabel(title)
        }
    }
}
