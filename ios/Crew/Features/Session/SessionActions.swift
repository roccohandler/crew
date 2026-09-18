// SPEC: Flow 3 (the base loop; quick complete; crash-proof — every tap saves) · S10 (numbers match the engine exactly;
// the workout becomes a POST when a celebration button is tapped) · E7 (two-a-days: first counts, extras bonus) · 5.3 optimistic
// write · A1 (the snapshot names its plan kind — the rotation pointer reads it back) · A2 (a standalone cardio log is a session of
// kind "cardio", created and completed in one call) · A3 (isPlannedDay is the caller's judgment: a bonus workout is unplanned, +25) ·
// A6 (the post's one summary line, with the server's rounding so the hydrated line matches). A21.9 / W4 (owner-approved 2026-09-17,
// A19.3 stands): complete() records the workout and creates NO post — the celebration shows a PREVIEW of what the tap will count;
// post(_:shareToCrew:) creates the post with the visibility the tapped button names, runs the engine for real and sends the post;
// a celebration the app died under is answered PRIVATELY at the next cold start (postUnanswered). Plain functions shared by
// HomeModel.quickComplete, SessionModel.complete and CardioLogModel.submit (C1). WRITTEN — UNVERIFIED (needs Mac). T024–T026

import Foundation

struct PostDraft: Equatable, Codable {
    var clientId: String
    var sessionClientId: String
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
    // SPEC: A21.9 — the one celebration whose button has not been tapped yet, remembered outside the Store (no schema change):
    // written by complete(), cleared by post(), read at the next cold start by postUnanswered()
    static let unansweredKey = "celebrationUnanswered"

    // SPEC: A1 · A3 — a LocalSession from the plan's template: the SNAPSHOT that later plan edits never touch; rows pre-filled
    // from targets; `kind` is the plan kind it runs, `isPlannedDay` whether today is an undone training day (else +25, V70)
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
    // logged minutes in seconds, distanceMeters optional — completed through the same path as any workout (engine, queue; A21.9:
    // the post follows the celebration's tap)
    static func logCardio(activity: SeedExercise, minutes: Int, distanceMeters: Int?, userId: String, timeZone: TimeZone = .current, now: Date = Date(), store: Store) throws -> CelebrationOutcome {
        let seconds = minutes * TimeUnits.secondsPerMinute
        let set = LocalSetLog(order: 0, targetReps: 0, actualReps: 0, weight: nil, holdSeconds: seconds, isWarmup: false)
        set.distanceMeters = distanceMeters
        set.done = true
        set.asPlanned = Completion.asPlanned(SetFacts(targetReps: 0, actualReps: 0, done: true, isWarmup: false)) // V33/V51
        let exercise = LocalSessionExercise(exerciseId: activity.id, name: activity.name, equipment: activity.equipment, type: "cardio", targetSets: 1, targetReps: 0, holdSeconds: seconds, order: 0, sets: [set])
        let session = LocalSession(clientId: UUID().uuidString.lowercased(), userId: userId, dayKey: DayKey.dayKey(for: now, tz: timeZone), status: "inProgress", workoutName: activity.name, workoutKind: "cardio", isPlannedDay: false, startedAt: now, timezone: timeZone.identifier, exercises: [exercise])
        _ = try insertAndQueue(session, now: now, store: store)
        guard let outcome = try complete(session, now: now, store: store) else { throw AppError.storage("cardio") } // one done work set: always complete (V51)
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

    // SPEC: V32 — ≥1 work set done completes. A21.9: the completion is RECORDED (the row, the patchSession op with no post) and
    // nothing is counted yet — the awards returned are a preview of what the tap will count (GamificationLocal.preview: the same
    // computation as apply, with the one post the tap inserts, nothing persisted). The celebration is remembered as unanswered.
    static func complete(_ session: LocalSession, now: Date = Date(), store: Store) throws -> CelebrationOutcome? {
        let facts = Completion.completionFacts(setFacts(session))
        guard facts.complete else { return nil }
        session.status = "completed"
        session.completedAt = now
        session.dayKey = DayKey.dayKey(for: now, tz: TimeZone(identifier: session.timezone) ?? .current)
        session.updatedAt = now
        try store.save()
        try SyncQueue.shared.enqueue(.patchSession, payload: PatchSessionPayload(sessionId: session.clientId, timezone: session.timezone, exercises: exerciseDTOs(session), status: "completed", completedAt: now, post: nil), now: now)
        // A14: a standalone cardio log is its own post type — the server writes the same value from the session kind (sessions.ts).
        // The ENGINE event is .workout: a walk pays a workout's XP; the streak counts only a planned day (V70, A22 G1 (a)).
        let weekdays = try GamificationLocal.trainingWeekdays(for: session.userId, store: store)
        var awards = try GamificationLocal.preview(.postCreated(kind: .workout, dayKey: session.dayKey, isPlannedDay: session.isPlannedDay, workoutCompleted: true, plannedWeekdays: weekdays), for: session.userId, store: store)
        awards.append(contentsOf: try AchievementFacts.newRecords(in: session, store: store).map { Award.prBadge(exercise: $0) }) // Flow 3 PR celebration, last in the canonical order
        let draft = PostDraft(clientId: UUID().uuidString.lowercased(), sessionClientId: session.clientId)
        rememberUnanswered(draft)
        let duration = Int(now.timeIntervalSince(session.startedAt))
        return CelebrationOutcome(setsDone: facts.setsDone, setsPlanned: facts.setsPlanned, durationSeconds: duration, awards: awards, postDraft: draft)
    }

    // SPEC: A21.9 · S10 · A6 — the tapped button creates the post with the visibility it names: the row (with its A6 line), the
    // engine for real, the queue (a second patchSession carrying `post`; the server creates the post once — sessions.ts
    // postLateIfMissing). The choice is made once: a session that already has its post is left alone.
    @discardableResult
    static func post(_ outcome: CelebrationOutcome, shareToCrew: Bool, now: Date = Date(), store: Store) throws -> [Award] {
        guard let session = try store.session(clientId: outcome.postDraft.sessionClientId) else { throw AppError.storage("session") }
        return try post(session, clientId: outcome.postDraft.clientId, shareToCrew: shareToCrew, now: now, store: store)
    }

    static func post(_ session: LocalSession, clientId: String, shareToCrew: Bool, now: Date, store: Store) throws -> [Award] {
        forgetUnanswered()
        guard try store.post(forSessionClientId: session.clientId) == nil else { return [] }
        let post = LocalPost(clientId: clientId, userId: session.userId, type: session.workoutKind == "cardio" ? "cardio" : "workout", sessionClientId: session.clientId, caption: "", mealTag: nil, shareToCrew: shareToCrew, dayKey: session.dayKey, isPlannedDay: session.isPlannedDay, workoutCompleted: true, earlierToday: false, createdAt: now)
        post.summary = JournalFacts.summaryLine(session, distanceUnit: AuthStore.shared.distanceUnit) // A6: the one line the celebration, the journal and the day card read — server rounding (JournalFacts)
        store.context.insert(post)
        try store.save()
        let weekdays = try GamificationLocal.trainingWeekdays(for: session.userId, store: store)
        let awards = try GamificationLocal.apply(.postCreated(kind: .workout, dayKey: session.dayKey, isPlannedDay: session.isPlannedDay, workoutCompleted: true, plannedWeekdays: weekdays), for: session.userId, store: store)
        let payload = PatchSessionPayload(sessionId: session.clientId, timezone: session.timezone, exercises: nil, status: "completed", completedAt: session.completedAt, post: CompletionPostDTO(clientId: clientId, shareToCrew: shareToCrew, caption: nil, photoKey: nil))
        try SyncQueue.shared.enqueue(.patchSession, payload: payload, now: now)
        return awards
    }

    // SPEC: A21.9 — a celebration the app died under (no button tapped) posts PRIVATELY at the next cold start, so the day still
    // counts and the phone and the server agree; a private post is the quiet default (S10). Nothing remembered → nothing happens.
    static func postUnanswered(userId: String, now: Date = Date(), store: Store) throws {
        guard let data = UserDefaults.standard.data(forKey: unansweredKey), let draft = try? JSONDecoder.crew.decode(PostDraft.self, from: data) else { return }
        guard let session = try store.session(clientId: draft.sessionClientId), session.userId == userId, session.status == "completed" else { forgetUnanswered(); return }
        _ = try post(session, clientId: draft.clientId, shareToCrew: false, now: now, store: store)
    }

    static func rememberUnanswered(_ draft: PostDraft) {
        if let data = try? JSONEncoder.crew.encode(draft) { UserDefaults.standard.set(data, forKey: unansweredKey) }
    }

    static func forgetUnanswered() { UserDefaults.standard.removeObject(forKey: unansweredKey) }

    // SPEC: Flow 3 quick complete — trained phone-free? One tap logs the planned workout at its targets (Home offers it only on
    // an undone training day, so the session is planned); the celebration's button then posts it (A21.9)
    static func quickComplete(from workout: LocalWorkoutTemplate, userId: String, now: Date = Date(), store: Store) throws -> CelebrationOutcome? {
        let session = try startSession(from: workout, kind: workout.kind, isPlannedDay: true, userId: userId, now: now, store: store)
        for exercise in session.exercises { for set in exercise.sets { set.done = true; set.asPlanned = true } }
        try store.save()
        return try complete(session, now: now, store: store)
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
