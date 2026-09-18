// SPEC: Flow 6 — [Start a Crew] → name + emoji → invite link → straight into iMessage; Captain tools (rename / change the emoji
// — E2, PATCH crews/[id], W3 under A21.2 2026-09-17 —, remove, regenerate link) visible only to the Captain (S13); "crew full"
// and revoked-link states explicit. WRITTEN — UNVERIFIED. T031

import SwiftUI

struct InviteScreen: View {
    @Bindable var model: CrewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                    if let crew = model.crew {
                        Text("\(crew.name) \(crew.emoji)").font(.title2.weight(.bold)).foregroundStyle(EmberColors.inkText)
                        Text("\(model.members.count)/\(SpecConstants.crewMaxMembers) members").font(.subheadline).foregroundStyle(EmberColors.secondaryText)
                        if model.members.count >= SpecConstants.crewMaxMembers {
                            Text("Crew full — \(SpecConstants.crewMaxMembers) is the max.").font(.body).foregroundStyle(EmberColors.inkText)
                        } else if let link = crew.inviteLink, let url = URL(string: link) {
                            ShareLink(item: url, message: Text("Join my crew on Crew: \(crew.name) \(crew.emoji)")) {
                                Text("Send invite link").font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.dayToggleMinPt))
                                    .foregroundStyle(EmberColors.primaryButtonLabel)
                                    .background(EmberColors.primaryButtonFill, in: RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous))
                            }
                        } else if !model.isCaptain {
                            Text("Ask your Captain for the link.").font(.body).foregroundStyle(EmberColors.inkText) // the link is the Captain's (S13)
                        }
                        if let notice = model.noticeLine { Text(notice).font(.footnote).foregroundStyle(EmberColors.secondaryText).accessibilityAddTraits(.updatesFrequently) }
                        if model.isCaptain {
                            captainTools(crew: crew)
                        }
                        Button("Leave crew") { Task { await model.leave(); dismiss() } }.font(.subheadline).foregroundStyle(EmberColors.danger).frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                    }
                }
                .padding(EmberTokens.Spacing.space24)
            }
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .onAppear { name = model.crew?.name ?? ""; emoji = model.crew?.emoji ?? "" }
        }
    }

    // SPEC: E2 · S13 · W3 — the Captain's tools: rename / new emoji (bounded by crewNameMaxChars / crewEmojiMaxChars, the same
    // limits the server enforces), regenerate the link, remove a member. A18.11: the fields are controls, so their boundary is
    // controlOutline.
    @ViewBuilder private func captainTools(crew: CrewDTO) -> some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
            Text("Rename crew").font(.headline).foregroundStyle(EmberColors.inkText)
            TextField("Crew name", text: $name)
                .onChange(of: name) { _, next in if next.count > SpecConstants.crewNameMaxChars { name = String(next.prefix(SpecConstants.crewNameMaxChars)) } }
                .modifier(InviteField())
            TextField("Emoji", text: $emoji)
                .onChange(of: emoji) { _, next in if next.count > SpecConstants.crewEmojiMaxChars { emoji = String(next.prefix(SpecConstants.crewEmojiMaxChars)) } }
                .modifier(InviteField())
            SecondaryButton(title: "Save name") { Task { await model.rename(name: name, emoji: emoji) } }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || emoji.isEmpty || (name == crew.name && emoji == crew.emoji))
        }
        SecondaryButton(title: "Regenerate link (old one dies)") { Task { await model.regenerateLink() } }
        ForEach(model.members.filter { $0.id != crew.captainId }) { member in
            HStack {
                Text(member.displayName).foregroundStyle(EmberColors.inkText)
                Spacer()
                Button("Remove") { Task { await model.captainRemove(memberId: member.id) } }.font(.subheadline).foregroundStyle(EmberColors.danger)
            }
            .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
        }
    }
}

// One text field's chrome: card fill, controlOutline boundary (A18.11), a 44 pt touch target (6.3)
private struct InviteField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(EmberTokens.Spacing.space12)
            .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
            .background(EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous).stroke(EmberColors.controlOutline, lineWidth: EmberTokens.Size.hairline))
    }
}
