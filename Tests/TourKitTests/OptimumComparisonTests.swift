import Foundation
import Testing

@testable import TourKit

/// The heuristic against the optimum from ``ExactSolver``.
///
/// Measured on 2520 instances (4–10 points, every variant, 30 seeds, two kinds of matrices):
/// - city-like matrices: optimal in 1258 of 1260 instances, at most 0.14% above the optimum;
/// - uniformly random matrices: optimal in 1249 of 1260, 0.06% above on average, but 7 instances more
///   than 5% above and the worst 30% above. Multi-start stops after 30 restarts, and on a tiny instance
///   all of them can fall back into the same local minimum; 300 restarts reach the optimum on all of them.
///
/// To save the report, create the folder first:
/// `mkdir -p .build/attachments && swift test --filter OptimumComparisonTests --attachments-path .build/attachments`.
@Suite("Comparison with the optimum")
struct OptimumComparisonTests {
    enum MatrixKind: String, CaseIterable, Sendable {
        case random
        case city

        func matrix(count: Int, seed: UInt64) -> CostMatrix {
            switch self {
            case .random: TestMatrices.random(count: count, seed: seed)
            case .city: TestMatrices.city(count: count, seed: seed)
            }
        }
    }

    let heuristic = HeuristicSolver()
    let exact = ExactSolver()

    @Test("Closed tours up to 5 points: always optimal", arguments: 2...5)
    func optimalForTinyTours(count: Int) throws {
        for seed in 0..<50 as Range<UInt64> {
            let problem = try TourProblem(costs: TestMatrices.random(count: count, seed: seed))
            let solution = try heuristic.solve(problem, deadline: .never)
            #expect(solution.cost == (try exact.solve(problem)).cost, "seed \(seed)")
        }
    }

    @Test("Closed tours from point 0 with 6–8 points: at most 5% above the optimum, as in pathly", arguments: 6...8)
    func nearOptimalForSmallTours(count: Int) throws {
        for seed in 0..<30 as Range<UInt64> {
            let problem = try TourProblem(costs: TestMatrices.random(count: count, seed: 1000 + seed))
            let optimum = try exact.solve(problem).cost
            let solution = try heuristic.solve(problem, deadline: .never)

            #expect(solution.cost / optimum - 1 <= 0.05, "seed \(seed): \(solution.cost) vs \(optimum)")
        }
    }

    @Test("Hundreds of instances up to 10 points, every variant", arguments: MatrixKind.allCases)
    func hundredsOfInstances(kind: MatrixKind) throws {
        var gaps: [Double] = []
        for count in 4...10 {
            for (start, end) in HeuristicSolverTests.variants {
                for seed in 0..<30 as Range<UInt64> {
                    let problem = try TourProblem(
                        costs: kind.matrix(count: count, seed: 7000 + seed), start: start, end: end)
                    let optimum = try exact.solve(problem).cost
                    let solution = try heuristic.solve(problem, deadline: .never)

                    #expect(TestMatrices.isValid(solution.order, for: problem))
                    #expect(solution.cost >= optimum * (1 - 1e-9), "The heuristic cannot beat the optimum")
                    gaps.append(solution.cost / optimum - 1)
                }
            }
        }

        let optimalCount = gaps.filter { $0 <= 1e-9 }.count
        let optimalShare = Double(optimalCount) / Double(gaps.count)
        let meanGap = gaps.reduce(0, +) / Double(gaps.count)
        let worstGap = gaps.max() ?? 0
        Attachment.record(
            String(
                format: "%@ matrices: optimal in %d of %d, mean gap %.3f%%, worst gap %.2f%%, above 5%%: %d",
                kind.rawValue, optimalCount, gaps.count, meanGap * 100, worstGap * 100, gaps.filter { $0 > 0.05 }.count
            ),
            named: "optimum-comparison-\(kind.rawValue).txt"
        )

        #expect(optimalShare >= 0.98)
        #expect(meanGap <= 0.005)
        if kind == .city {
            #expect(worstGap <= 0.01)
        }
    }
}
