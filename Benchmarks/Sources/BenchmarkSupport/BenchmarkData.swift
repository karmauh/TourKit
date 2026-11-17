import Foundation
import TourKit

/// The benchmark data: TSPLIB instances with their best known tour lengths, and random matrices.
public enum BenchmarkData {
    /// The `Data` folder next to this package's `Package.swift`.
    public static let dataDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // BenchmarkSupport
        .deletingLastPathComponent()  // Sources
        .deletingLastPathComponent()  // Benchmarks
        .appendingPathComponent("Data")

    /// A TSPLIB instance used in the quality benchmark.
    public struct Instance: Sendable {
        /// The instance name, also the file name without `.atsp`.
        public let name: String
        /// The best known tour length from TSPLIB's list of solutions for asymmetric TSPs.
        public let bestKnown: Double
    }

    /// The instances of the quality benchmark, smallest first.
    ///
    /// Best known values from TSPLIB's "Best known solutions for asymmetric TSPs"
    /// (`ATSP-BEST.html`, where kro124p is listed as kro124). See `Data/README.md`.
    public static let instances: [Instance] = [
        .init(name: "br17", bestKnown: 39),
        .init(name: "ftv33", bestKnown: 1286),
        .init(name: "p43", bestKnown: 5620),
        .init(name: "ftv64", bestKnown: 1839),
        .init(name: "ft70", bestKnown: 38673),
        .init(name: "kro124p", bestKnown: 36230),
        .init(name: "rbg443", bestKnown: 2720),
    ]

    /// The command that downloads the instance files, which are not stored in the repository.
    public static let downloadCommand = "Scripts/download-tsplib.sh"

    /// The instances whose files are not in the `Data` folder yet.
    public static var missingInstances: [Instance] {
        instances.filter { !FileManager.default.fileExists(atPath: fileURL(for: $0).path) }
    }

    /// Reads an instance from the `Data` folder.
    public static func load(_ instance: Instance) throws -> TSPLIBInstance {
        try TSPLIBInstance(contentsOf: fileURL(for: instance))
    }

    private static func fileURL(for instance: Instance) -> URL {
        dataDirectory.appendingPathComponent("\(instance.name).atsp")
    }

    /// A random asymmetric matrix with whole costs 60–1800, the same as in TourKit's tests.
    public static func randomMatrix(count: Int, seed: UInt64) -> CostMatrix {
        var generator = SplitMix64(seed: seed)
        var values = [Double](repeating: 0, count: count * count)
        for from in 0..<count {
            for to in 0..<count where from != to {
                values[from * count + to] = Double.random(in: 60...1800, using: &generator).rounded()
            }
        }
        return try! CostMatrix(count: count, values: values)
    }
}

/// The SplitMix64 generator, repeated here because TourKit keeps its own copy internal.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}
