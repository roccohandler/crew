// SPEC: A21.3 / W4 (owner-approved 2026-09-17) — the invite CODE is the crew's inviteToken, nothing new (Appendix A A21 GAP
// reading, owner-confirmed). A person pastes whatever they were sent: the bare code, the full link, or a link with a query or
// fragment; this reads the code out of any of them. Twin of ios/Crew/Shared/InviteCode.swift — same rules, same answers.
// Pure (C2); the /join page and the hero's "I have an invite" call it.

const JOIN_SEGMENT = "/join/";

export function inviteToken(raw: string): string | null {
  const trimmed = raw.trim();
  if (trimmed.length === 0) return null;
  const afterJoin = trimmed.includes(JOIN_SEGMENT) ? trimmed.slice(trimmed.lastIndexOf(JOIN_SEGMENT) + JOIN_SEGMENT.length) : trimmed;
  const token = afterJoin.split(/[?#/]/, 1)[0] ?? "";
  if (token.length === 0 || /\s/.test(token)) return null;
  return token;
}
