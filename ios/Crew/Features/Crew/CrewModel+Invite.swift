// SPEC: 5.6.2 CrewModel — the invite-code half (A21.3 / W4, owner-approved 2026-09-17): lookUpInvite · joinByCode on the empty Crew tab
// (JoinByCodeSheet), the CODE shown and copied from the Invite screen, and the 1C photo prompt's once-only consumption. Plain
// extension of CrewModel — no new layer; split from CrewModel.swift for C9 (the file cap). WRITTEN — UNVERIFIED (needs Mac).

import UIKit

extension CrewModel {
    // SPEC: A21.3 · S13 — the pasted code is the crew's inviteToken; the public preview names the crew ("Night Shift 🌙 · 1 of 10 in
    // the crew"); a dead code reads the server's line, a full crew its own (the same lines OnboardingModel.lookUpInvite shows)
    func lookUpInvite() async {
        inviteCodeError = nil
        invitePreview = nil
        guard let token = InviteCode.token(from: inviteCode) else { inviteCodeError = "That doesn't look like an invite code. Paste the code or the whole link."; return }
        isLookingUpInvite = true
        defer { isLookingUpInvite = false }
        do {
            let preview = try await Api.shared.crewPreview(token: token)
            invitePreview = preview
            if preview.full { inviteCodeError = "Crew full — \(SpecConstants.crewMaxMembers) is the max. Ask about a second crew." }
        } catch let error as AppError { inviteCodeError = error.userLine } catch { inviteCodeError = AppError.invalidResponse.userLine }
    }

    // SPEC: A21.3 — Join from the preview: the server's refusals (already in a crew, full, dead, blocked) read under the field
    func joinByCode() async {
        guard let token = InviteCode.token(from: inviteCode), invitePreview != nil else { return }
        do {
            _ = try await Api.shared.joinCrew(token: token)
            PhotoPromptFlag.markPending() // 1C
            inviteCode = ""
            invitePreview = nil
            await refresh()
        } catch let error as AppError { inviteCodeError = error.userLine } catch { inviteCodeError = AppError.invalidResponse.userLine }
    }

    // SPEC: 1C — the photo prompt shows once, on the first Crew screen after a join or a create, for an account without a photo
    func consumePhotoPrompt() -> Bool { crew != nil && PhotoPromptFlag.consume() }

    // SPEC: A21.3 — the Invite screen shows the CODE beside the link: the same token, for a friend who will paste it into the app
    var inviteCodeText: String? { crew?.inviteLink.flatMap { InviteCode.token(from: $0) } }

    func copyInviteCode() {
        guard let code = inviteCodeText else { return }
        UIPasteboard.general.string = code
        noticeLine = "Code copied."
    }
}
