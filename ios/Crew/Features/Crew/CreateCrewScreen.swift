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
                Text("Name your crew").font(.title2.weight(.bold)).foregroundStyle(EmberColors.inkText)
                TextField("Dawn Patrol", text: $name)
                    .padding(EmberTokens.Spacing.space12)
                    .background(EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Spacing.space12, style: .continuous))
                    .onChange(of: name) { _, value in if value.count > SpecConstants.crewNameMaxChars { name = String(value.prefix(SpecConstants.crewNameMaxChars)) } }
                HStack(spacing: EmberTokens.Spacing.space8) {
                    ForEach(["🌅", "🔥", "💪", "🏋️", "🌊", "⚡️", "🦍", "🥑"], id: \.self) { option in
                        Button(option) { emoji = option }.font(.title2)
                            .frame(width: CGFloat(SpecConstants.minTouchTargetPt), height: CGFloat(SpecConstants.minTouchTargetPt))
                            .background(emoji == option ? EmberColors.hairline : EmberColors.card, in: Circle())
                    }
                }
                if let error = model.loadError { Text(error).font(.footnote).foregroundStyle(EmberColors.danger) }
                PrimaryButton(title: "Start a crew") { Task { await model.create(name: name.trimmingCharacters(in: .whitespaces), emoji: emoji); if model.crew != nil { dismiss() } } }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                Spacer()
            }
            .padding(EmberTokens.Spacing.space24)
            .background(EmberColors.canvas.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
