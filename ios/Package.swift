// swift-tools-version:5.10
// The engine half of the iPhone app as a Swift package, so the twin engine and its vectors run on the open-source toolchain
// — Docker on the Windows build machine today, an ubuntu CI runner tomorrow — before any Mac exists. The app itself (SwiftUI,
// SwiftData, the screens) still needs Xcode: project.yml is the real project; this file exists only for `swift test`.
// SPEC: 8.1 (a vector failing on EITHER engine blocks every merge) · 8.3 (plan generator property test, SwapFinder, DayKey)
// · XI T016–T020 ("green BOTH"). Run: docker run --rm -v "<repo>:/repo" -w /repo/ios swift:5.10 swift test
import PackageDescription

let package = Package(
    name: "CrewEngine",
    platforms: [.macOS(.v14), .iOS(.v17)],
    targets: [
        // Everything under Engine/ plus the generated constants and seed data: Foundation only, no Apple UI framework
        .target(
            name: "Crew",
            path: "Crew",
            sources: ["Engine", "Generated/SpecConstants.swift", "Generated/SeedData.swift", "TimeUnits.swift", "Api/ApiModels.swift"]
        ),
        // The tests that touch the engine alone; VectorFiles falls back to ../shared/vectors when no bundle carries them
        .testTarget(
            name: "CrewEngineTests",
            dependencies: ["Crew"],
            path: "CrewTests",
            sources: ["VectorFiles.swift", "VectorRunnerTests.swift", "VectorRunnerCrewTests.swift", "AchievementsTests.swift", "PlanGeneratorTests.swift", "SwapFinderTests.swift", "LapsedUserTests.swift", "SpecConstantsTests.swift"]
        ),
    ]
)
