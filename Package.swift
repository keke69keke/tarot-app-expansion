// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TarotApp",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)  // enables running tests on macOS CI
    ],
    products: [
        .library(name: "TarotCore",          targets: ["TarotCore"]),
        .library(name: "TarotData",          targets: ["TarotData"]),
        .library(name: "TarotUI",            targets: ["TarotUI"]),
        .library(name: "TarotNotifications", targets: ["TarotNotifications"]),
        .library(name: "TarotContent",       targets: ["TarotContent"]),
        .executable(name: "TarotApp",        targets: ["TarotApp"]),
    ],
    dependencies: [
        // SwiftCheck: property-based testing framework (test-only)
        .package(
            url: "https://github.com/typelift/SwiftCheck.git",
            from: "0.12.0"
        ),
    ],
    targets: [

        // MARK: - TarotCore
        .target(
            name: "TarotCore",
            path: "TarotCore"
        ),
        .testTarget(
            name: "TarotCoreTests",
            dependencies: [
                "TarotCore",
                "TarotData",
                "TarotContent",
                "TarotNotifications",
                .product(name: "SwiftCheck", package: "SwiftCheck"),
            ],
            path: "TarotTests/Unit"
        ),

        // MARK: - TarotData
        .target(
            name: "TarotData",
            dependencies: ["TarotCore", "TarotContent"],
            path: "TarotData",
            exclude: ["README.md", "SettingsRepository/README.md"]
        ),
        .testTarget(
            name: "TarotDataTests",
            dependencies: [
                "TarotData",
                "TarotCore",
                .product(name: "SwiftCheck", package: "SwiftCheck"),
            ],
            path: "TarotTests/Integration"
        ),
        .testTarget(
            name: "TarotSmokeTests",
            dependencies: [
                "TarotCore",
                "TarotData",
                "TarotContent",
            ],
            path: "TarotTests/Smoke"
        ),

        // MARK: - TarotUI
        .target(
            name: "TarotUI",
            dependencies: ["TarotCore", "TarotData", "TarotContent", "TarotNotifications"],
            path: "TarotUI",
            exclude: ["README.md"]
        ),

        // MARK: - TarotApp
        .executableTarget(
            name: "TarotApp",
            dependencies: ["TarotUI"],
            path: "TarotApp",
            exclude: ["Core", "Presentation", "Info.plist"]
        ),

        // MARK: - TarotNotifications
        .target(
            name: "TarotNotifications",
            dependencies: ["TarotCore"],
            path: "TarotNotifications",
            exclude: ["README.md"]
        ),

        // MARK: - TarotContent
        .target(
            name: "TarotContent",
            path: "TarotContent",
            exclude: ["README.md"],
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
