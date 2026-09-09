// SPEC: Flow 6 — [Start a Crew] → name + emoji → invite link → straight into iMessage; Captain tools (rename, remove,
// regenerate link) visible only to the Captain (S13); "crew full" and revoked-link states explicit. WRITTEN — UNVERIFIED. T031

import SwiftUI

struct InviteScreen: View {
    @Bindable var model: CrewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
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
                    if model.isCaptain {
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
                    Button("Leave crew") { Task { await model.leave(); dismiss() } }.font(.subheadline).foregroundStyle(EmberColors.danger).frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                }
                Spacer()
            }
            .padding(EmberTokens.Spacing.space24)
            .background(EmberColors.canvas.ignoresSafeArea())
            .navigationTitle("Invite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}
