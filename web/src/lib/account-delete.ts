// SPEC: E9 (delete-account cascades everywhere) · E18 (delete is real; re-signup = genuine fresh start) · 8.2 Account (posts
// vanish from streams, blobs deleted, 404s everywhere after) · Part IV (one "account deleted" email). The order matters: leave
// the crew first (captaincy passes / archive), then every collection, the user last. W5 (owner-approved 2026-09-17): the leftovers
// the audit found go too — other people's reactions on the user's posts (orphans once the posts are gone), reports the user
// filed or that name the user or their posts, and the dev/test outbox rows (email by address, push by user); the "account
// deleted" email is written AFTER the sweep, so it is the one row that remains. T041
import { ObjectId } from "mongodb";
import { removeMember } from "@/lib/crews";
import { blocks, crewMemberships, dayTemplates, events, gamificationStates, mealLogs, messages, nutritionTargets, passwordResets, pauses, plans, posts, pushTokens, reactions, refreshTokens, reports, savedMeals, sessions, users } from "@/lib/db";
import { emailOutbox, sendAccountDeletedEmail } from "@/lib/email";
import { notificationLog } from "@/lib/notification-facts";
import { deletePhotosOf } from "@/lib/photos";
import { pushOutbox } from "@/lib/push";

export async function deleteAccount(userId: ObjectId, now: Date = new Date()): Promise<void> {
  const user = await (await users()).findOne({ _id: userId });
  if (user === null) return;
  const membership = await (await crewMemberships()).findOne({ userId });
  if (membership !== null) await removeMember(userId, membership.crewId.toHexString(), userId, user.displayName, now);
  const myPostIds = (await (await posts()).find({ userId }, { projection: { _id: 1 } }).toArray()).map((doc) => doc._id);
  await Promise.all([
    (await posts()).deleteMany({ userId }),
    (await sessions()).deleteMany({ userId }),
    (await plans()).deleteMany({ userId }),
    (await reactions()).deleteMany({ $or: [{ userId }, { targetId: { $in: myPostIds } }] }), // theirs, and everyone's on their posts
    (await messages()).deleteMany({ userId }),
    (await pauses()).deleteMany({ userId }),
    (await blocks()).deleteMany({ $or: [{ blockerId: userId }, { blockedId: userId }] }),
    (await reports()).deleteMany({ $or: [{ reporterId: userId }, { targetType: "user", targetId: userId }, { targetType: "post", targetId: { $in: myPostIds } }] }),
    (await refreshTokens()).deleteMany({ userId }),
    (await passwordResets()).deleteMany({ userId }),
    (await pushTokens()).deleteMany({ userId }),
    (await gamificationStates()).deleteMany({ userId }),
    (await nutritionTargets()).deleteMany({ userId }), // addendum §2: the bodyweight goes with the targets
    (await savedMeals()).deleteMany({ userId }),
    (await dayTemplates()).deleteMany({ userId }),
    (await mealLogs()).deleteMany({ userId }),
    (await notificationLog()).deleteMany({ userId }),
    (await emailOutbox()).deleteMany({ to: user.email }),
    (await pushOutbox()).deleteMany({ userId }),
    (await events()).updateMany({ userId }, { $set: { userId: null } }),
  ]);
  await deletePhotosOf(userId);
  await (await users()).deleteOne({ _id: userId });
  await sendAccountDeletedEmail(user.email);
}
