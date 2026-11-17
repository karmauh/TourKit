// Prints a Markdown table comparing HeuristicSolver with the best known TSPLIB tour lengths.
//
// Run in release mode, otherwise the times are meaningless:
//
//     swift run -c release TSPLIBReport
//
// An optional argument changes the number of restarts, e.g. `TSPLIBReport 300`. Without it the
// solver uses its default configuration, which is what the README table shows.

import BenchmarkSupport
import Foundation
import TourKit

var configuration = HeuristicSolver.Configuration()
if CommandLine.arguments.count > 1 {
    guard let restarts = Int(CommandLine.arguments[1]), restarts >= 0 else {
        print("Usage: TSPLIBReport [restarts]")
        exit(1)
    }
    configuration.restarts = restarts
}
let solver = HeuristicSolver(configuration: configuration)

print("| Instance | Points | Best known | TourKit | Gap | Time | Restarts |")
print("|---|--:|--:|--:|--:|--:|--:|")

var gaps: [Double] = []
for instance in BenchmarkData.instances {
    let data = try BenchmarkData.load(instance)
    let problem = try TourProblem(costs: data.costs)
    let solution = try await solver.solve(problem)

    let gap = (solution.cost - instance.bestKnown) / instance.bestKnown * 100
    gaps.append(gap)
    let restarts = "\(solution.statistics.completedRestarts)/\(configuration.restarts)"
    let stopped = solution.stopReason == .timeLimit ? " (time limit)" : ""

    print(
        "| \(instance.name) | \(data.count) | \(format(instance.bestKnown)) | \(format(solution.cost))"
            + " | \(format(gap, digits: 2)) % | \(milliseconds(solution.statistics.elapsed)) ms"
            + " | \(restarts)\(stopped) |"
    )
}

print()
print("Mean gap: \(format(gaps.reduce(0, +) / Double(gaps.count), digits: 2)) %.")
print(
    "HeuristicSolver: \(configuration.restarts) restarts,"
        + " seed 0x\(String(configuration.seed, radix: 16, uppercase: true)),"
        + " time limit \(configuration.timeLimit.map { "\($0)" } ?? "none")."
)
print("Machine: \(cpuName()), \(ProcessInfo.processInfo.operatingSystemVersionString).")

func format(_ value: Double, digits: Int = 0) -> String {
    value.formatted(.number.precision(.fractionLength(digits)).grouping(.never).locale(Locale(identifier: "en_US")))
}

func milliseconds(_ duration: Duration) -> String {
    let (seconds, attoseconds) = duration.components
    return format(Double(seconds) * 1000 + Double(attoseconds) / 1e15, digits: 1)
}

func cpuName() -> String {
    var size = 0
    guard sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0) == 0, size > 0 else { return "unknown CPU" }
    var buffer = [CChar](repeating: 0, count: size)
    guard sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0) == 0 else { return "unknown CPU" }
    return String(decoding: buffer.prefix { $0 != 0 }.map(UInt8.init(bitPattern:)), as: UTF8.self)
}
