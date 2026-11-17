// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault")
]

let package = Package(
    name: "TourKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "TourKit", targets: ["TourKit"])
    ],
    targets: [
        .target(
            name: "TourKit",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "TourKitTests",
            dependencies: ["TourKit"],
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
