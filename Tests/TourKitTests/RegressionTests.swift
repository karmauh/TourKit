import Testing

@testable import TourKit

/// Tours that pathly's `RouteOptimizer` found before the code moved to TourKit.
///
/// Recorded by compiling pathly's `Domain/RouteOptimization` on its own and running it with the default
/// configuration and no time limit on `TestMatrices.random(count:seed:)`. Identical tours prove that the move,
/// the path representation, the penalty for forbidden edges and the relative improvement threshold left
/// the algorithm unchanged on closed tours.
@Suite("Regression against pathly")
struct RegressionTests {
    struct Recorded: Sendable, CustomTestStringConvertible {
        let count: Int
        let seed: UInt64
        let cost: Double
        let order: [Int]

        var testDescription: String { "\(count) points, seed \(seed)" }
    }

    @Test("Same tour and cost as pathly", arguments: recorded)
    func sameTourAsPathly(_ expected: Recorded) throws {
        let problem = try TourProblem(costs: TestMatrices.random(count: expected.count, seed: expected.seed))

        let solution = try HeuristicSolver().solve(problem, deadline: .never)

        #expect(solution.order == expected.order)
        #expect(solution.cost == expected.cost)
        #expect(solution.statistics.completedRestarts == 30)
    }

    static let recorded: [Recorded] = [
        .init(count: 6, seed: 11, cost: 4094, order: [0, 2, 1, 4, 5, 3]),
        .init(count: 12, seed: 12, cost: 3352, order: [0, 10, 8, 1, 3, 11, 4, 5, 2, 9, 7, 6]),
        .init(
            count: 30, seed: 13, cost: 4808,
            order: [
                0, 9, 13, 4, 29, 28, 19, 15, 12, 7, 10, 11, 2, 25, 21, 23, 22, 16, 3, 20, 14, 18, 8, 6, 24, 17, 27, 1,
                26, 5,
            ]
        ),
        .init(
            count: 60, seed: 14, cost: 7339,
            order: [
                0, 7, 30, 15, 18, 43, 36, 58, 3, 39, 1, 19, 22, 26, 37, 35, 59, 25, 6, 4, 48, 42, 32, 20, 51, 50, 8,
                53, 45, 31, 28, 54, 41, 10, 52, 11, 44, 47, 5, 12, 34, 9, 16, 13, 49, 29, 23, 2, 21, 24, 33, 40, 46,
                56, 38, 55, 27, 14, 17, 57,
            ]
        ),
        .init(
            count: 100, seed: 15, cost: 11540,
            order: [
                0, 29, 82, 32, 95, 96, 92, 44, 65, 9, 93, 21, 17, 94, 56, 2, 22, 66, 48, 37, 4, 10, 69, 76, 71, 97, 49,
                11, 68, 98, 78, 72, 46, 41, 86, 50, 88, 23, 62, 38, 99, 81, 26, 58, 63, 42, 40, 31, 14, 16, 73, 43, 28,
                83, 87, 7, 27, 33, 74, 84, 5, 54, 51, 34, 90, 35, 53, 30, 20, 61, 13, 3, 77, 8, 39, 18, 19, 1, 47, 80,
                45, 12, 6, 25, 55, 60, 59, 36, 64, 15, 52, 57, 79, 85, 75, 70, 67, 89, 24, 91,
            ]
        ),
        .init(
            count: 150, seed: 16, cost: 15504,
            order: [
                0, 8, 96, 64, 120, 119, 144, 20, 75, 123, 81, 71, 114, 44, 92, 78, 149, 110, 100, 108, 140, 143, 136,
                111, 95, 34, 31, 12, 122, 89, 15, 23, 99, 142, 135, 130, 137, 17, 118, 2, 61, 32, 134, 56, 131, 14,
                139, 63, 51, 121, 50, 94, 3, 127, 83, 129, 5, 77, 18, 4, 43, 38, 40, 98, 87, 59, 27, 1, 41, 67, 62,
                109, 85, 29, 90, 48, 145, 70, 53, 103, 116, 112, 76, 57, 102, 36, 54, 33, 28, 11, 19, 25, 68, 147, 113,
                30, 84, 74, 45, 73, 82, 80, 88, 13, 9, 55, 46, 146, 132, 138, 106, 141, 107, 21, 58, 39, 115, 97, 66,
                105, 101, 35, 52, 124, 79, 24, 91, 47, 22, 69, 133, 26, 37, 7, 125, 72, 117, 93, 128, 42, 104, 148,
                10, 16, 60, 126, 6, 65, 49, 86,
            ]
        ),
    ]
}
