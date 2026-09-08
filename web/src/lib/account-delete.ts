// SPEC: E9 (delete-account cascades everywhere) · E18 (delete is real; re-signup = genuine fresh start) · 8.2 Account (posts
// vanish from streams, blobs deleted, 404s everywhere after) · Part IV (one "account deleted" email). The order matters: leave
// the crew first (captaincy passes / archive), then every collection, the user last. T041
import { ObjectId } from "mongodb";
import { removeMember } from "@/lib/crews";
import { blocks, crewMemberships, events, gamificationStates, messages, passwordResets, pauses, plans, posts, pushTokens, reactions, refreshTokens, sessions, users } from "@/lib/db";
import { sendAccountDeletedEmail } from "@/lib/email";
import { notificationLog } from "@/lib/notification-facts";
import { deletePhotosOf } from "@/lib/photos";

export async function deleteAccount(userId: ObjectId, now: Date = new Date()): Promise<void> {
  const user = await (await users()).findOne({ _id: userId });
  if (user === null) return;
  const membership = await (await crewMemberships()).findOne({ userId });
  if (membership !== null) await removeMember(userId, membership.crewId.toHexString(), userId, user.displayName, now);
  await Promise.all([
    (await posts()).deleteMany({ userId }),
    (await sessions()).deleteMany({ userId }),
    (await plans()).deleteMany({ userId }),
    (await reactions()).deleteMany({ userId }),
    (await messages()).deleteMany({ userId }),
    (await pauses()).deleteMany({ userId }),
    (await blocks()).deleteMany({ $or: [{ blockerId: userId }, { blockedId: userId }] }),
    (await refreshTokens()).deleteMany({ userId }),
    (await passwordResets()).deleteMany({ userId }),
    (await pushTokens()).deleteMany({ userId }),
    (await gamificationStates()).deleteMany({ userId }),
    (await notificationLog()).deleteMany({ userId }),
    (await events()).updateMany({ userId }, { $set: { userId: null } }),
  ]);
  await deletePhotosOf(userId);
  await (await users()).deleteOne({ _id: userId });
  await sendAccountDeletedEmail(user.email);
}
