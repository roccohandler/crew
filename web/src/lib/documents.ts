// SPEC: Part IX — the data model, final shape and invariants, as MongoDB documents: User, Plan, Session and their
// nested shapes. The social documents (Post, Crew, …) are in documents-social.ts; operational ones in
// documents-auth.ts. One concrete shape per collection; no hierarchies (C1). T009.
import type { ObjectId } from "mongodb";

export type DayKey = string; // "YYYY-MM-DD", 3 AM-adjusted (E8)

export interface UserDoc {
  _id: ObjectId;
  email: string; // Apple relay addresses are stored as given
  emailLower: string; // unique index target
  authProvider: "email" | "apple";
  appleSub?: string; // unique when present
  passwordHash?: string; // scrypt (Part IV); absent for Apple-only accounts
  displayName: string;
  profilePhotoKey: string | null; // null renders initials (E1)
  units: "lb" | "kg";
  timezone: string; // IANA, follows the device (E8)
  reminderTime: string | null; // "HH:MM" local, chosen by the user (G12); null = no reminder
  welcomeBackAckDay?: string | null; // E4: the day the user answered the welcome-back screen (absent = never)
  eulaAcceptedAt: Date; // E9: EULA at signup
  createdAt: Date;
  deletedAt?: Date; // set during the cascade; the document is removed at the end
}

export interface ExerciseTemplateDoc {
  exerciseId: string; // seed id
  name: string; // ≤ exerciseNameMaxChars
  pattern: string;
  equipment: string;
  type: "strength" | "mobility";
  targetSets: number; // ≤ planMaxSetsPerExercise
  targetReps: number;
  targetRepsMax?: number; // G7 rep ranges
  targetWeight?: number;
  holdSeconds?: number; // mobility only
  perSide?: boolean;
  order: number;
}

export interface WorkoutTemplateDoc {
  weekday: number; // ISO 1 = Monday … 7 = Sunday (E20)
  name: string;
  kind: "push" | "pull" | "legs" | "fullBodyA" | "fullBodyB" | "custom";
  exercises: ExerciseTemplateDoc[]; // ≤ planMaxExercisesPerDay
}

export interface PlanDoc {
  _id: ObjectId;
  userId: ObjectId; // UNIQUE — one plan per user
  workouts: WorkoutTemplateDoc[]; // one per training weekday; missing weekday = rest day
  updatedAt: Date;
}

export interface SetLogDoc {
  targetReps: number;
  actualReps: number;
  weight: number | null; // "—" is a complete set forever
  holdSeconds: number | null;
  isWarmup: boolean; // excluded from x/y (Flow 3)
  done: boolean;
  asPlanned: boolean; // V33
}

export interface SessionExerciseDoc {
  exerciseId: string;
  name: string;
  equipment: string;
  type: "strength" | "mobility";
  targetSets: number;
  targetReps: number;
  holdSeconds: number | null;
  order: number;
  skipped: boolean; // neutral skips (Flow 3)
  sets: SetLogDoc[];
}

export interface SessionDoc {
  _id: ObjectId;
  clientId: string; // client UUID — idempotency (8.2 ④)
  userId: ObjectId;
  dayKey: DayKey; // of completion (V07); of start while in progress
  status: "inProgress" | "completed" | "discarded";
  workoutName: string;
  isPlannedDay: boolean; // snapshot — immune to later plan edits
  startedAt: Date;
  completedAt: Date | null;
  timezone: string;
  exercises: SessionExerciseDoc[];
  updatedAt: Date;
}
