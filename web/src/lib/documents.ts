// SPEC: Part IX — the data model, final shape and invariants, as MongoDB documents: User, Plan, Session and their
// nested shapes. The social documents (Post, Crew, …) are in documents-social.ts; operational ones in
// documents-auth.ts. One concrete shape per collection; no hierarchies (C1). T009. Amended A1 (rotation plan), A2 (cardio),
// A7 (notification preferences) — owner-directed 2026-09-08.
import type { ObjectId } from "mongodb";

export type DayKey = string; // "YYYY-MM-DD", 3 AM-adjusted (E8)

// SPEC: A7 — per-row notification toggles; a user document without the field means every toggle is on
export interface NotificationPrefs {
  workoutReminder: boolean;
  streakRisk: boolean;
  crewActivity: boolean;
}

export interface UserDoc {
  _id: ObjectId;
  email: string; // Apple relay addresses are stored as given
  emailLower: string; // unique index target
  authProvider: "email" | "apple";
  appleSub?: string; // unique when present
  passwordHash?: string; // scrypt (Part IV); absent for Apple-only accounts
  displayName: string;
  profilePhotoKey: string | null; // null renders initials (E1); a key from `photos` with purpose "profile", owned by the user
  units: "lb" | "kg";
  timezone: string; // IANA, follows the device (E8)
  reminderTime: string | null; // "HH:MM" local, chosen by the user (G12); null = no reminder
  notificationPrefs?: NotificationPrefs; // A7: absent = all true
  welcomeBackAckDay?: string | null; // E4: the day the user answered the welcome-back screen (absent = never)
  eulaAcceptedAt: Date; // E9: EULA at signup
  createdAt: Date;
  deletedAt?: Date; // set during the cascade; the document is removed at the end
}

export type ExerciseType = "strength" | "mobility" | "cardio"; // A2: cardio is duration-based like mobility
export type WorkoutKind = "push" | "pull" | "legs" | "fullBodyA" | "fullBodyB" | "custom";

export interface ExerciseTemplateDoc {
  exerciseId: string; // seed id
  name: string; // ≤ exerciseNameMaxChars
  pattern: string;
  equipment: string;
  type: ExerciseType;
  targetSets: number; // ≤ planMaxSetsPerExercise
  targetReps: number;
  targetRepsMax?: number; // G7 rep ranges
  targetWeight?: number;
  holdSeconds?: number; // seconds for mobility holds AND cardio blocks (A2)
  perSide?: boolean;
  order: number;
}

// SPEC: A1 — one workout per kind; the list order IS the rotation order (no weekday: the rotation assigns days)
export interface WorkoutTemplateDoc {
  kind: WorkoutKind;
  name: string;
  exercises: ExerciseTemplateDoc[]; // ≤ planMaxExercisesPerDay
}

export interface PlanDoc {
  _id: ObjectId;
  userId: ObjectId; // UNIQUE — one plan per user
  trainingWeekdays: number[]; // ISO 1 = Monday … 7 = Sunday, sorted, unique, ≥ 1 (A1)
  workouts: WorkoutTemplateDoc[]; // ordered cycle; kinds unique (A1)
  updatedAt: Date;
}

export interface SetLogDoc {
  targetReps: number;
  actualReps: number;
  weight: number | null; // "—" is a complete set forever
  holdSeconds: number | null; // mobility holds and cardio blocks (A2)
  distanceMeters: number | null; // cardio only, optional (A2); never pace
  isWarmup: boolean; // excluded from x/y (Flow 3)
  done: boolean;
  asPlanned: boolean; // V33
}

export interface SessionExerciseDoc {
  exerciseId: string;
  name: string;
  equipment: string;
  type: ExerciseType;
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
  workoutKind: string | null; // A1: the plan kind this session ran (drives the rotation pointer); "cardio" for a standalone log (A2); null = legacy (inferred from the name)
  isPlannedDay: boolean; // snapshot — immune to later plan edits
  startedAt: Date;
  completedAt: Date | null;
  timezone: string;
  exercises: SessionExerciseDoc[];
  updatedAt: Date;
}
