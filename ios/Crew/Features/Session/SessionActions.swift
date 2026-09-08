// SPEC: Flow 3 (the base loop; quick complete; crash-proof — every tap saves) · S10 (numbers match the engine exactly;
// the workout is now a POST) · E7 (two-a-days: first counts, extras bonus) · 5.3 optimistic write. Plain functions shared by
// HomeModel.quickComplete and SessionModel.complete (the third occurrence rule, C1, would have found them anyway).
// WRITTEN — UNVERIFIED (needs Mac). T024–T026

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
    // A LocalSession from the plan's template: the SNAPSHOT that later plan edits never touch; rows pre-filled from targets
    static func startSession(from workout: LocalWorkoutTemplate, userId: String, timeZone: TimeZone = .current, now: Date = Date(), store: Store) throws -> LocalSession {
        let exercises = workout.exercises.sorted { $0.order < $1.order }.map { template -> LocalSessionExercise in
            let sets = (0..<template.targetSets).map { index in
                LocalSetLog(order: index, targetReps: template.targetReps, actualReps: template.targetReps, weight: template.targetWeight, holdSeconds: template.holdSeconds, isWarmup: false)
            }
            return LocalSessionExercise(exerciseId: template.exerciseId, name: template.name, equipment: template.equipment, type: template.type, targetSets: template.targetSets, targetReps: template.targetReps, holdSeconds: template.holdSeconds, order: template.order, sets: sets)
        }
        let session = LocalSession(clientId: UUID().uuidString.lowercased(), userId: userId, dayKey: DayKey.dayKey(for: now, tz: timeZone), status: "inProgress", workoutName: workout.name, isPlannedDay: true, startedAt: now, timezone: timeZone.identifier, exercises: exercises)
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

    // SPEC: V32 — ≥1 work set done completes; then the post, the engine, the queue
    static func complete(_ session: LocalSession, shareToCrew: Bool, now: Date = Date(), store: Store) throws -> CelebrationOutcome? {
        let facts = Completion.completionFacts(setFacts(session))
        guard facts.complete else { return nil }
        session.status = "completed"
        session.completedAt = now
        session.dayKey = DayKey.dayKey(for: now, tz: TimeZone(identifier: session.timezone) ?? .current)
        session.updatedAt = now
        let postClientId = UUID().uuidString.lowercased()
        let post = LocalPost(clientId: postClientId, userId: session.userId, type: "workout", sessionClientId: session.clientId, caption: "", mealTag: nil, shareToCrew: shareToCrew, dayKey: session.dayKey, isPlannedDay: session.isPlannedDay, workoutCompleted: true, earlierToday: false, createdAt: now)
        store.context.insert(post)
        try store.save()
        var awards = try GamificationLocal.apply(.postCreated(kind: .workout, dayKey: session.dayKey, isPlannedDay: session.isPlannedDay, workoutCompleted: true), for: session.userId, store: store)
        awards.append(contentsOf: try AchievementFacts.newRecords(in: session, store: store).map { Award.prBadge(exercise: $0) }) // Flow 3 PR celebration, last in the canonical order
        let payload = PatchSessionPayload(sessionId: session.clientId, timezone: session.timezone, exercises: exerciseDTOs(session), status: "completed", completedAt: now, post: CompletionPostDTO(clientId: postClientId, shareToCrew: shareToCrew, caption: nil, photoKey: nil))
        try SyncQueue.shared.enqueue(.patchSession, payload: payload, now: now)
        let duration = Int(now.timeIntervalSince(session.startedAt))
        return CelebrationOutcome(setsDone: facts.setsDone, setsPlanned: facts.setsPlanned, durationSeconds: duration, awards: awards, postDraft: PostDraft(clientId: postClientId, sessionClientId: session.clientId, shareToCrew: shareToCrew))
    }

    // SPEC: Flow 3 quick complete — trained phone-free? One tap logs the planned workout at its targets
    static func quickComplete(from workout: LocalWorkoutTemplate, userId: String, shareToCrew: Bool, now: Date = Date(), store: Store) throws -> CelebrationOutcome? {
        let session = try startSession(from: workout, userId: userId, now: now, store: store)
        for exercise in session.exercises { for set in exercise.sets { set.done = true; set.asPlanned = true } }
        try store.save()
        return try complete(session, shareToCrew: shareToCrew, now: now, store: store)
    }

    static func exerciseDTOs(_ session: LocalSession) -> [SessionExerciseDTO] {
        session.exercises.sorted { $0.order < $1.order }.map { exercise in
            SessionExerciseDTO(exerciseId: exercise.exerciseId, name: exercise.name, equipment: exercise.equipment, type: exercise.type, targetSets: exercise.targetSets, targetReps: exercise.targetReps, holdSeconds: exercise.holdSeconds, order: exercise.order, skipped: exercise.skipped, sets: exercise.sets.sorted { $0.order < $1.order }.map { SetLogDTO(targetReps: $0.targetReps, actualReps: $0.actualReps, weight: $0.weight, holdSeconds: $0.holdSeconds, isWarmup: $0.isWarmup, done: $0.done) })
        }
    }

    static func createPayload(_ session: LocalSession) -> CreateSessionPayload {
        CreateSessionPayload(clientId: session.clientId, timezone: session.timezone, startedAt: session.startedAt, workoutSnapshot: WorkoutSnapshotDTO(name: session.workoutName, weekday: DayKey.isoWeekday(session.dayKey), isPlannedDay: session.isPlannedDay, exercises: exerciseDTOs(session)))
    }
}
