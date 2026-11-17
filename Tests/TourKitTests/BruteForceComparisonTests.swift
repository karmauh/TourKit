import Testing

@testable import TourKit

/// The heuristic against the optimum found by checking every order. Stage 3 replaces brute force
/// with ``ExactSolver`` and extends this comparison to hundreds of instances.
@Suite("Comparison with the optimum (brute force)")
struct BruteForceComparisonTests {
    let solver = HeuristicSolver()

    @Test("Closed tours up to 5 points: always optimal", arguments: [2, 3, 4, 5])
    func optimalForTinyTours(count: Int) throws {
        for seed in 0..<50 as Range<UInt64> {
            let problem = try TourProblem(costs: TestMatrices.random(count: count, seed: seed))
            let solution = try solver.solve(problem, deadline: .never)
            #expect(abs(solution.cost - TestMatrices.bruteForceOptimum(problem)) < 1e-6, "seed \(seed)")
        }
    }

    @Test("Closed tours from point 0 with 6–8 points: at most 5% above the optimum", arguments: [6, 7, 8])
    func nearOptimalForSmallTours(count: Int) throws {
        for seed in 0..<30 as Range<UInt64> {
            let problem = try TourProblem(costs: TestMatrices.random(count: count, seed: 1000 + seed))
            let optimum = TestMatrices.bruteForceOptimum(problem)
            let solution = try solver.solve(problem, deadline: .never)

            #expect(solution.cost >= optimum - 1e-6, "The heuristic cannot beat the optimum")
            #expect(solution.cost / optimum - 1 <= 0.05, "seed \(seed): \(solution.cost) vs \(optimum)")
        }
    }

    /// A single instance may end far from the optimum (two of 540 measured end about 15% above it), because
    /// multi-start explores few perturbations of a tiny tour. The average shows the typical quality.
    @Test(
        "6–8 points, every variant: never better than the optimum, at most 1% above it on average",
        arguments: [6, 7, 8], HeuristicSolverTests.variants.indices
    )
    func nearOptimalOnAverage(count: Int, variant: Int) throws {
        let (start, end) = HeuristicSolverTests.variants[variant]
        var totalGap = 0.0
        let seeds = 0..<30 as Range<UInt64>
        for seed in seeds {
            let problem = try TourProblem(
                costs: TestMatrices.random(count: count, seed: 1000 + seed), start: start, end: end)
            let optimum = TestMatrices.bruteForceOptimum(problem)
            let solution = try solver.solve(problem, deadline: .never)

            #expect(solution.cost >= optimum - 1e-6, "The heuristic cannot beat the optimum")
            totalGap += solution.cost / optimum - 1
        }
        #expect(totalGap / Double(seeds.count) <= 0.01)
    }
}
