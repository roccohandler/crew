// SPEC: docs/api.md POST reports — report any post/message/crew-name/user; the Report is stored and the moderation inbox is
// emailed via Resend — that email IS the manual review queue (E9: no AI scanning) · T034
import { ObjectId } from "mongodb";
import { errorResponse, json, notFound } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { crews, messages, posts, reports, users } from "@/lib/db";
import { sendReportReceivedEmail } from "@/lib/email";
import { logEvent } from "@/lib/events";
import { HttpStatus } from "@/lib/http-status";
import { createReportSchema } from "@/lib/validate-crews";

async function previewOf(targetType: string, targetId: ObjectId): Promise<string> {
  if (targetType === "post") return (await (await posts()).findOne({ _id: targetId }))?.caption ?? "";
  if (targetType === "message") return (await (await messages()).findOne({ _id: targetId }))?.body ?? "";
  if (targetType === "crewName") return (await (await crews()).findOne({ _id: targetId }))?.name ?? "";
  return (await (await users()).findOne({ _id: targetId }))?.displayName ?? "";
}

export async function POST(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = createReportSchema.parse(await req.json());
    const targetId = new ObjectId(body.targetId);
    const preview = await previewOf(body.targetType, targetId);
    if (preview.length === 0) throw notFound("Reported item");
    const report = { _id: new ObjectId(), targetType: body.targetType, targetId, reporterId: new ObjectId(userId), reason: body.reason, status: "open" as const, createdAt: new Date() };
    await (await reports()).insertOne(report);
    await sendReportReceivedEmail({ reportId: report._id.toHexString(), targetType: body.targetType, targetId: body.targetId, reporterId: userId, reason: body.reason, targetPreview: preview });
    await logEvent(userId, "report_filed", { targetType: body.targetType });
    return json({ reportId: report._id.toHexString() }, HttpStatus.created);
  } catch (error) {
    return errorResponse(error);
  }
}
