import Benchmark
import BenchmarkSupport
import TourKit

// Run with `swift package benchmark` from the Benchmarks folder. Counting allocations needs jemalloc.
let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration = .init(
        metrics: [.wallClock, .cpuTotal, .mallocCountTotal, .peakMemoryResident],
        maxDuration: .seconds(5),
        maxIterations: 200
    )

    // 150 points is the size from the 2-second criterion in the task description.
    for count in [50, 100, 150, 200] {
        let problem = try! TourProblem(costs: BenchmarkData.randomMatrix(count: count, seed: UInt64(count)))
        let solver = HeuristicSolver()

        // The deadline never expires, so every iteration does the same work: all restarts.
        Benchmark("HeuristicSolver, \(count) points") { benchmark in
            for _ in benchmark.scaledIterations {
                blackHole(try solver.solve(problem, deadline: .never))
            }
        }
    }
}
