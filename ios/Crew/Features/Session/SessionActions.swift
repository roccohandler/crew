// SPEC: Flow 3 (the base loop; quick complete; crash-proof — every tap saves) · S10 (numbers match the engine exactly;
// the workout is now a POST) · E7 (two-a-days: first counts, extras bonus) · 5.3 optimistic write · A1 (the snapshot names
// its plan kind — the rotation pointer reads it back) · A2 (a standalone cardio log is a session of kind "cardio", created and
// completed in one call) · A3 (isPlannedDay is the caller's judgment: a bonus workout is unplanned, +25) · A6 (the post's one
// summary line, with the server's rounding so the hydrated line matches). Plain functions shared by HomeModel.quickComplete,
// SessionModel.complete and CardioLogModel.submit (C1). WRITTEN — UNVERIFIED (needs Mac). T024–T026

import Foundation

struct PostDraft: Equatable {
    var clientId: String
    var sessionClientId: String
    var caption = ""
    var shareToCrew: Bool
}

struct CelebrationOutcome: Equatable {
    let setsDone: Int
    let setsPlanned: Int
    let durationSeconds: Int
    let awards: [Award]
    let postDraft: PostDraft
}

@MainActor
enum SessionActions {
    // SPEC: A1 · A3 — a LocalSession from the plan's template: the SNAPSHOT that later plan edits never touch; rows pre-filled
    // from targets; `kind` is the plan kind it runs, `isPlannedDay` whether today is an undone training day (else +25, V30/V31)
    static func startSession(from workout: LocalWorkoutTemplate, kind: String, isPlannedDay: Bool, userId: String, timeZone: TimeZone = .current, now: Date = Date(), store: Store) throws -> LocalSession {
        // SPEC: A12 — every strength row opens at the last ACTUAL performance of that exercise, not at "—" (Flow 3's
        // promise, finally used). The history is read once for the whole session, newest first.
        let history = (try? store.completedSessions(for: userId)) ?? []
        let exercises = workout.exercises.sorted { $0.order < $1.order }.map { template -> LocalSessionExercise in
            let facts = SetPrefill.facts(from: prefillHistory(exerciseId: template.exerciseId, in: history))
            let openingReps = SetPrefill.openingReps(targetReps: template.targetReps, facts: facts)
            let openingWeight = SetPrefill.openingWeight(targetWeight: template.targetWeight, facts: facts)
            let sets = (0..<template.targetSets).map { index in
                LocalSetLog(order: index, targetReps: template.targetReps, actualReps: openingReps, weight: openingWeight, holdSeconds: template.holdSeconds, isWarmup: false, weightUnit: facts?.weightUnit)
            }
            return LocalSessionExercise(exerciseId: template.exerciseId, name: template.name, equipment: template.equipment, type: template.type, targetSets: template.targetSets, targetReps: template.targetReps, holdSeconds: template.holdSeconds, order: template.order, sets: sets)
        }
        let session = LocalSession(clientId: UUID().uuidString.lowercased(), userId: userId, dayKey: DayKey.dayKey(for: now, tz: timeZone), status: "inProgress", workoutName: workout.name, workoutKind: kind, isPlannedDay: isPlannedDay, startedAt: now, timezone: timeZone.identifier, exercises: exercises)
        return try insertAndQueue(session, now: now, store: store)
    }

    // SPEC: A2 — a standalone cardio log from Home: a session of kind "cardio", unplanned (+25 per V30/V31; it sustains the
    // streak like any post; A1: it never advances the rotation), one cardio exercise with one done set — holdSeconds are the
    // logged minutes in seconds, distanceMeters optional — completed through the same path as any workout (post, engine, queue)
    static func logCardio(activity: SeedExercise, minutes: Int, distanceMeters: Int?, shareToCrew: Bool = true, userId: String, timeZone: TimeZone = .current, now: Date = Date(), store: Store) throws -> CelebrationOutcome {
        let seconds = minutes * TimeUnits.secondsPerMinute
        let set = LocalSetLog(order: 0, targetReps: 0, actualReps: 0, weight: nil, holdSeconds: seconds, isWarmup: false)
        set.distanceMeters = distanceMeters
        set.done = true
        set.asPlanned = Completion.asPlanned(SetFacts(targetReps: 0, actualReps: 0, done: true, isWarmup: false)) // V33/V51
        let exercise = LocalSessionExercise(exerciseId: activity.id, name: activity.name, equipment: activity.equipment, type: "cardio", targetSets: 1, targetReps: 0, holdSeconds: seconds, order: 0, sets: [set])
        let session = LocalSession(clientId: UUID().uuidString.lowercased(), userId: userId, dayKey: DayKey.dayKey(for: now, tz: timeZone), status: "inProgress", workoutName: activity.name, workoutKind: "cardio", isPlannedDay: false, startedAt: now, timezone: timeZone.identifier, exercises: [exercise])
        _ = try insertAndQueue(session, now: now, store: store)
        guard let outcome = try complete(session, shareToCrew: shareToCrew, now: now, store: store) else { throw AppError.storage("cardio") } // one done work set: always complete (V51)
        return outcome
    }

    // SPEC: A12 — one exercise's rows out of the completed history, newest session first; SetPrefill picks from them
    private static func prefillHistory(exerciseId: String, in history: [LocalSession]) -> [[PrefillSet]] {
        history.compactMap { session in
            guard let row = session.exercises.first(where: { $0.exerciseId == exerciseId }), row.type == "strength" else { return nil }
            return row.sets.map { PrefillSet(actualReps: $0.actualReps, weight: $0.weight, weightUnit: $0.weightUnit, done: $0.done, isWarmup: $0.isWarmup) }
        }
    }

    // 5.3 optimistic write: the row first, then the createSession op (8.3 ordering — before any patchSession that follows)
    private static func insertAndQueue(_ session: LocalSession, now: Date, store: Store) throws -> LocalSession {
        store.context.insert(session)
        try store.save()
        try SyncQueue.shared.enqueue(.createSession, payload: createPayload(session), now: now)
        return session
    }

    static func setFacts(_ session: LocalSession) -> [SetFacts] {
        session.exercises.sorted { $0.order < $1.order }.flatMap { exercise in
            exercise.sets.sorted { $0.order < $1.order }.map { SetFacts(targetReps: $0.targetReps, actualReps: $0.actualReps, done: $0.done, isWarmup: $0.isWarmup) }
        }
    }

    // SPEC: V32 — ≥1 work set done completes; then the post (with its A6 line), the engine, the queue
    static func complete(_ session: LocalSession, shareToCrew: Bool, now: Date = Date(), store: Store) throws -> CelebrationOutcome? {
        let facts = Completion.completionFacts(setFacts(session))
        guard facts.complete else { return nil }
        session.status = "completed"
        session.completedAt = now
        session.dayKey = DayKey.dayKey(for: now, tz: TimeZone(identifier: session.timezone) ?? .current)
        session.updatedAt = now
        let postClientId = UUID().uuidString.lowercased()
        let post = LocalPost(clientId: postClientId, userId: session.userId, type: "workout", sessionClientId: session.clientId, caption: "", mealTag: nil, shareToCrew: shareToCrew, dayKey: session.dayKey, isPlannedDay: session.isPlannedDay, workoutCompleted: true, earlierToday: false, createdAt: now)
        post.summary = JournalFacts.summaryLine(session, distanceUnit: AuthStore.shared.distanceUnit) // A6: the one line the celebration, the journal and the day card read — server rounding (JournalFacts)
        store.context.insert(post)
        try store.save()
        var awards = try GamificationLocal.apply(.postCreated(kind: .workout, dayKey: session.dayKey, isPlannedDay: session.isPlannedDay, workoutCompleted: true), for: session.userId, store: store)
        awards.append(contentsOf: try AchievementFacts.newRecords(in: session, store: store).map { Award.prBadge(exercise: $0) }) // Flow 3 PR celebration, last in the canonical order
        let payload = PatchSessionPayload(sessionId: session.clientId, timezone: session.timezone, exercises: exerciseDTOs(session), status: "completed", completedAt: now, post: CompletionPostDTO(clientId: postClientId, shareToCrew: shareToCrew, caption: nil, photoKey: nil))
        try SyncQueue.shared.enqueue(.patchSession, payload: payload, now: now)
        let duration = Int(now.timeIntervalSince(session.startedAt))
        return CelebrationOutcome(setsDone: facts.setsDone, setsPlanned: facts.setsPlanned, durationSeconds: duration, awards: awards, postDraft: PostDraft(clientId: postClientId, sessionClientId: session.clientId, shareToCrew: shareToCrew))
    }

    // SPEC: Flow 3 quick complete — trained phone-free? One tap logs the planned workout at its targets (Home offers it only on
    // an undone training day, so the session is planned)
    static func quickComplete(from workout: LocalWorkoutTemplate, userId: String, shareToCrew: Bool, now: Date = Date(), store: Store) throws -> CelebrationOutcome? {
        let session = try startSession(from: workout, kind: workout.kind, isPlannedDay: true, userId: userId, now: now, store: store)
        for exercise in session.exercises { for set in exercise.sets { set.done = true; set.asPlanned = true } }
        try store.save()
        return try complete(session, shareToCrew: shareToCrew, now: now, store: store)
    }

    static func exerciseDTOs(_ session: LocalSession) -> [SessionExerciseDTO] {
        session.exercises.sorted { $0.order < $1.order }.map { exercise in
            SessionExerciseDTO(exerciseId: exercise.exerciseId, name: exercise.name, equipment: exercise.equipment, type: exercise.type, targetSets: exercise.targetSets, targetReps: exercise.targetReps, holdSeconds: exercise.holdSeconds, order: exercise.order, skipped: exercise.skipped, sets: exercise.sets.sorted { $0.order < $1.order }.map { SetLogDTO(targetReps: $0.targetReps, actualReps: $0.actualReps, weight: $0.weight, holdSeconds: $0.holdSeconds, distanceMeters: $0.distanceMeters, weightUnit: $0.weightUnit, isWarmup: $0.isWarmup, done: $0.done) })
        }
    }

    // SPEC: A1 — the snapshot carries its kind ("cardio" for a log); the server derives the weekday from the day it lands on
    static func createPayload(_ session: LocalSession) -> CreateSessionPayload {
        CreateSessionPayload(clientId: session.clientId, timezone: session.timezone, startedAt: session.startedAt, workoutSnapshot: WorkoutSnapshotDTO(name: session.workoutName, kind: session.workoutKind, isPlannedDay: session.isPlannedDay, exercises: exerciseDTOs(session)))
    }
}
