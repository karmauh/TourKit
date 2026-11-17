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
    dependencies: [
        // Build-time only: adds `swift package generate-documentation`.
        // No product of this package links against it.
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.5.0")
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
