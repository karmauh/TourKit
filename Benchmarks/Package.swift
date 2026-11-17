// swift-tools-version: 6.2

import PackageDescription

// A separate package, so users of TourKit never download package-benchmark.
let package = Package(
    name: "TourKitBenchmarks",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/ordo-one/package-benchmark", exact: "1.38.1"),
    ],
    targets: [
        .target(
            name: "BenchmarkSupport",
            dependencies: [
                .product(name: "TourKit", package: "TourKit")
            ]
        ),
        .executableTarget(
            name: "TSPLIBReport",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "TourKit", package: "TourKit"),
            ]
        ),
        .executableTarget(
            name: "TourKitBenchmarks",
            dependencies: [
                "BenchmarkSupport",
                .product(name: "TourKit", package: "TourKit"),
                .product(name: "Benchmark", package: "package-benchmark"),
            ],
            path: "Benchmarks/TourKitBenchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
            ]
        ),
        .testTarget(
            name: "BenchmarkSupportTests",
            dependencies: ["BenchmarkSupport"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
