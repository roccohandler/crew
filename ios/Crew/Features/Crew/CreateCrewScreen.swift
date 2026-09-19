// SPEC: Flow 6 — [Start a Crew] → name (≤ crewNameMaxChars) + emoji → the crew exists and the invite link follows (S13) · Part
// III (ink acts: monochrome controls) · C10 one screen per file (split out of InviteScreen.swift, R-055).
// WRITTEN — UNVERIFIED (needs Mac). T031

import SwiftUI

struct CreateCrewScreen: View {
    @Bindable var model: CrewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = "🌅"

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                Text("Name your crew").typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink)
                TextField("Dawn Patrol", text: $name)
                    .typeRole(EmberTokens.Typography.cardSubheading)
                    .foregroundStyle(EmberColors.ink)
                    .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt)) // R-083 (11): the platform's field, without field chrome
                    .onChange(of: name) { _, value in if value.count > SpecConstants.crewNameMaxChars { name = String(value.prefix(SpecConstants.crewNameMaxChars)) } }
                HStack(spacing: EmberTokens.Spacing.space8) {
                    ForEach(["🌅", "🔥", "💪", "🏋️", "🌊", "⚡️", "🦍", "🥑"], id: \.self) { option in
                        Button(option) { emoji = option }.font(.title2)
                            .frame(width: CGFloat(SpecConstants.minTouchTargetPt), height: CGFloat(SpecConstants.minTouchTargetPt))
                            .overlay(Circle().strokeBorder(EmberColors.ink, lineWidth: emoji == option ? EmberTokens.Focus.checkRing : 0)) // the chosen one: an ink ring, like a check
                            .accessibilityAddTraits(emoji == option ? .isSelected : [])
                    }
                }
                if let error = model.loadError { Text(error).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink) } // A28 (a): red only in a destructive confirm
                PrimaryButton(title: "Start a crew") { Task { await model.create(name: name.trimmingCharacters(in: .whitespaces), emoji: emoji); if model.crew != nil { dismiss() } } }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                Spacer()
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.vertical, EmberTokens.Spacing.space16)
            .background(EmberColors.card.ignoresSafeArea()) // A28 (f): the sheet surface
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        .tint(EmberColors.ink)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(EmberTokens.Focus.cardRadius)
    }
}
