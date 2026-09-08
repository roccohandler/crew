// SPEC: Part IV email touchpoints (Resend — the complete list: password reset · report received · account deleted;
// transactional only, NEVER marketing) · Part III voice (warm gym buddy) · 6.6 copy (sentence case, no "!").
// Without RESEND_API_KEY every email is written to the `emailOutbox` collection instead — the dev/test transport.
import { ObjectId } from "mongodb";
import { Resend } from "resend";
import { getDb } from "@/lib/db";
import { SpecConstants } from "@/generated/spec-constants";

export interface OutboundEmail {
  to: string;
  subject: string;
  text: string;
  kind: "passwordReset" | "reportReceived" | "accountDeleted";
}

type OutboxDoc = OutboundEmail & { _id: ObjectId; sentAt: Date };

export async function emailOutbox() {
  return (await getDb()).collection<OutboxDoc>("emailOutbox");
}

async function deliver(email: OutboundEmail): Promise<void> {
  const apiKey = process.env.RESEND_API_KEY ?? "";
  if (apiKey.length === 0) {
    await (await emailOutbox()).insertOne({ _id: new ObjectId(), ...email, sentAt: new Date() });
    return;
  }
  const resend = new Resend(apiKey);
  const result = await resend.emails.send({ from: process.env.RESEND_FROM ?? "Crew <crew@example.com>", to: email.to, subject: email.subject, text: email.text });
  if (result.error) throw new Error(`Resend: ${result.error.message}`);
}

// SPEC: Part IV — single-use token, 30-min expiry, gym-buddy voice, one link
export async function sendPasswordResetEmail(to: string, resetLink: string): Promise<void> {
  await deliver({
    kind: "passwordReset",
    to,
    subject: "Reset your Crew password",
    text: [
      "Hey — you asked for a new password. One tap and you're back in:",
      "",
      resetLink,
      "",
      `The link works once and expires in ${SpecConstants.passwordResetTokenExpiryMinutes} minutes. Didn't ask for this? Ignore it and nothing changes.`,
      "",
      "— Crew",
    ].join("\n"),
  });
}

// SPEC: Part IV — the moderation inbox IS the manual review queue (E9: no AI scanning)
export async function sendReportReceivedEmail(details: { reportId: string; targetType: string; targetId: string; reporterId: string; reason: string; targetPreview: string }): Promise<void> {
  const inbox = process.env.MODERATION_INBOX ?? "moderation@example.com";
  await deliver({
    kind: "reportReceived",
    to: inbox,
    subject: `Report ${details.reportId}: ${details.targetType} ${details.targetId}`,
    text: [
      `A report needs a human look.`,
      "",
      `Target: ${details.targetType} ${details.targetId}`,
      `Reporter: ${details.reporterId}`,
      `Reason: ${details.reason}`,
      "",
      "Target preview:",
      details.targetPreview,
      "",
      "Resolve it from the reports collection (status: resolved) after acting.",
    ].join("\n"),
  });
}

// SPEC: Part IV — one confirmation, states the cascade is done (E9, E18)
export async function sendAccountDeletedEmail(to: string): Promise<void> {
  await deliver({
    kind: "accountDeleted",
    to,
    subject: "Your Crew account is deleted",
    text: [
      "Done. Your account, plan, workouts, posts and photos are gone from Crew, and your crew no longer sees you.",
      "",
      "If you ever come back, it's a genuine fresh start.",
      "",
      "— Crew",
    ].join("\n"),
  });
}
