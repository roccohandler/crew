// Test helpers for the vector runners: load shared/vectors/*.vectors.json from the CrewTests bundle and turn JSON into
// engine values. WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import XCTest
@testable import Crew

enum VectorFiles {
    struct Loaded {
        let file: String
        let vectors: [[String: Any]]
    }

    // shared/vectors relative to THIS source file — the directory the vectors actually live in, for the runner that has no
    // resource bundle: `swift test` on ios/Package.swift (the engine on the open-source toolchain, Docker or Linux CI).
    static var repoVectorsURL: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("shared/vectors")
    }

    static func load() throws -> [Loaded] {
        var urls = (try? FileManager.default.contentsOfDirectory(at: repoVectorsURL, includingPropertiesForKeys: nil)) ?? []
        #if canImport(Darwin)
        // The Xcode runner reads its own bundle: project.yml copies ../shared/vectors as a folder reference (a "vectors"
        // directory inside the bundle); a flat copy would land at the top level — accept either, so the loader does not
        // depend on how XcodeGen wires the phase. (On Linux these return NSURL, and no bundle carries the vectors anyway.)
        let bundle = Bundle(for: VectorRunnerTests.self)
        urls += (bundle.urls(forResourcesWithExtension: "json", subdirectory: "vectors") ?? [])
        urls += (bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])
        #endif
        urls = urls.filter { $0.lastPathComponent.hasSuffix(".vectors.json") }
        XCTAssertFalse(urls.isEmpty, "no vector files found — check shared/vectors, or project.yml CrewTests resources")
        return try urls.sorted { $0.lastPathComponent < $1.lastPathComponent }.map { url in
            let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
            return Loaded(file: url.lastPathComponent, vectors: object?["vectors"] as? [[String: Any]] ?? [])
        }
    }

    static func decode<T: Decodable>(_ type: T.Type, from json: Any) throws -> T {
        try JSONDecoder.crew.decode(T.self, from: JSONSerialization.data(withJSONObject: json))
    }

    // Events and crew posts may name the day as at + tz; the DayKey engine resolves it (V09, V10)
    static func resolveDay(_ json: [String: Any]) throws -> String {
        if let dayKey = json["dayKey"] as? String { return dayKey }
        let at = try XCTUnwrap(json["at"] as? String)
        let tz = try XCTUnwrap(TimeZone(identifier: try XCTUnwrap(json["tz"] as? String)))
        let instant = try XCTUnwrap(ISO8601DateFormatter().date(from: at))
        return DayKey.dayKey(for: instant, tz: tz)
    }

    static func pauses(_ json: Any?) throws -> [Pause] {
        try decode([Pause].self, from: json ?? [])
    }

    // The award JSON shape of shared/vectors/README.md
    static func json(of award: Award) -> [String: Any] {
        switch award {
        case .xp(let amount, let reason): return ["award": "xp", "amount": amount, "reason": reason.rawValue]
        case .streakTo(let value): return ["award": "streakTo", "value": value]
        case .comeback: return ["award": "comeback"]
        case .perfectWeek: return ["award": "perfectWeek"]
        case .shieldEarned: return ["award": "shieldEarned"]
        case .shieldConsumed: return ["award": "shieldConsumed"]
        case .levelUp(let value): return ["award": "levelUp", "value": value]
        case .achievement(let id): return ["award": "achievement", "id": id]
        case .prBadge(let exercise): return ["award": "prBadge", "exercise": exercise]
        }
    }

    static func publicStateJson(_ state: PublicState) -> [String: Any] {
        ["currentStreak": state.currentStreak, "longestStreak": state.longestStreak, "totalXP": state.totalXP, "level": state.level, "shields": state.shields, "lastCountedDayKey": state.lastCountedDayKey as Any, "earnedAchievementIds": state.earnedAchievementIds]
    }
}
