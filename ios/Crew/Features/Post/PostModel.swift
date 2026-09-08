// SPEC: 5.6.2 PostModel — state: mode(.camera|.library|.text), photo?, caption, mealTag (time-guessed), shareToCrew; actions:
// capture · pick · repeatYesterday · submit (optimistic: Store insert + queue op). Flow 4: camera-first, time-smart tags,
// "same as yesterday" ↻, text-only is legit, same-day backfill ("earlier today"), no filters. E5: camera denied → text-first.
// 6.2: shutter → optimistic "posted" < 500 ms. WRITTEN — UNVERIFIED (needs Mac). T027

import Foundation
import Observation
import UIKit

enum PostMode: Equatable {
    case camera, library, text
}

@Observable
@MainActor
final class PostModel {
    var mode: PostMode = .camera
    var photo: UIImage?
    var caption = ""
    var mealTag: MealTag
    var shareToCrew: Bool
    var earlierToday = false
    var repeated = false
    var submitError: String?
    var posted = false

    private let store: Store
    private let userId: String
    private let timeZone: TimeZone

    init(store: Store = .shared, userId: String? = nil, now: Date = Date(), timeZone: TimeZone = .current, cameraAvailable: Bool = true) {
        self.store = store
        self.userId = userId ?? AuthStore.shared.currentUser?.id ?? "local"
        self.timeZone = timeZone
        self.mealTag = MealTag.tagFor(date: now, timeZone: timeZone)
        self.shareToCrew = UserDefaults.standard.object(forKey: "shareToCrewDefault") as? Bool ?? true
        self.mode = cameraAvailable ? .camera : .text
    }

    // Flow 4 "Same as yesterday" — meal-preppers repost yesterday's meal in one tap, marked ↻
    func yesterdaysMeal(now: Date = Date()) -> LocalPost? {
        let yesterday = DayKey.addDays(DayKey.dayKey(for: now, tz: timeZone), -1)
        return (try? store.posts(for: userId, dayKey: yesterday))?.last { $0.type == "meal" }
    }

    func repeatYesterday(now: Date = Date()) {
        guard let meal = yesterdaysMeal(now: now) else { return }
        caption = meal.caption
        if let tag = meal.mealTag.flatMap(MealTag.init(rawValue:)) { mealTag = tag }
        if let path = meal.localPhotoPath, let image = UIImage(contentsOfFile: path) { photo = image }
        repeated = true
        mode = photo == nil ? .text : .library
    }

    var canSubmit: Bool { photo != nil || !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    // SPEC: 5.3 optimistic write — mutate SwiftData → engine apply → enqueue → (server reconciles later)
    func submit(now: Date = Date()) {
        guard canSubmit else { return }
        do {
            let dayKey = DayKey.dayKey(for: now, tz: timeZone)
            let isPlannedDay = (try? store.plan(for: userId)?.workouts.contains { $0.weekday == DayKey.isoWeekday(dayKey) }) ?? false
            let type = photo == nil && caption.isEmpty ? "text" : "meal"
            let post = LocalPost(clientId: UUID().uuidString.lowercased(), userId: userId, type: type, sessionClientId: nil, caption: repeated ? "↻ \(caption)" : caption, mealTag: mealTag.rawValue, shareToCrew: shareToCrew, dayKey: dayKey, isPlannedDay: isPlannedDay, workoutCompleted: false, earlierToday: earlierToday, createdAt: now)
            if let photo { post.localPhotoPath = try savePhotoLocally(photo, clientId: post.clientId) }
            store.context.insert(post)
            try store.save()
            _ = try GamificationLocal.apply(.postCreated(kind: type == "meal" ? .meal : .text, dayKey: dayKey, isPlannedDay: isPlannedDay, workoutCompleted: false), for: userId, store: store)
            try SyncQueue.shared.enqueue(.createPost, payload: PendingPostPayload(clientId: post.clientId, type: type, caption: post.caption, mealTag: mealTag.rawValue, shareToCrew: shareToCrew, timezone: timeZone.identifier, isPlannedDay: isPlannedDay, workoutCompleted: false, earlierToday: earlierToday, createdAt: now, localPhotoPath: post.localPhotoPath), now: now)
            UserDefaults.standard.set(shareToCrew, forKey: "shareToCrewDefault")
            posted = true
        } catch {
            submitError = AppError.storage("post").userLine
        }
    }

    // No filters, no editing: the JPEG bytes go straight to the outbox folder (E19 keeps them until delivered)
    private func savePhotoLocally(_ image: UIImage, clientId: String) throws -> String {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appending(path: "outbox")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: "\(clientId).jpg")
        guard let data = image.jpegData(compressionQuality: Double(SpecConstants.photoJpegQuality) / Double(SpecConstants.percentScale)) else { throw AppError.storage("photo") }
        try data.write(to: url, options: .atomic)
        return url.path
    }
}

struct PendingPostPayload: Codable {
    let clientId: String
    let type: String
    let caption: String
    let mealTag: String
    let shareToCrew: Bool
    let timezone: String
    let isPlannedDay: Bool
    let workoutCompleted: Bool
    let earlierToday: Bool
    let createdAt: Date
    let localPhotoPath: String?
}
