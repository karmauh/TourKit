import Testing

@testable import TourKit

@Suite("ExactSolver")
struct ExactSolverTests {
    let solver = ExactSolver()

    @Test(
        "Matches brute force for every variant up to 8 points",
        arguments: 2...8, HeuristicSolverTests.variants.indices
    )
    func matchesBruteForce(count: Int, variant: Int) throws {
        let (start, end) = HeuristicSolverTests.variants[variant]
        for seed in 0..<15 as Range<UInt64> {
            let matrix =
                seed.isMultiple(of: 2)
                ? TestMatrices.random(count: count, seed: 500 + seed)
                : TestMatrices.city(count: count, seed: 500 + seed)
            let problem = try TourProblem(costs: matrix, start: start, end: end)

            let solution = try solver.solve(problem)

            #expect(TestMatrices.isValid(solution.order, for: problem), "seed \(seed)")
            #expect(solution.cost == TestMatrices.referenceCost(of: solution.order, in: problem))
            let optimum = TestMatrices.bruteForceOptimum(problem)
            #expect(abs(solution.cost - optimum) <= 1e-9 * optimum, "seed \(seed): \(solution.cost) vs \(optimum)")
        }
    }

    @Test("Reports an optimal stop and trivial statistics")
    func statistics() throws {
        let problem = try TourProblem(costs: TestMatrices.random(count: 9, seed: 1))
        let solution = try solver.solve(problem)

        #expect(solution.stopReason == .optimal)
        #expect(solution.statistics.initialCost == solution.cost)
        #expect(solution.statistics.completedRestarts == 0)
    }

    @Test("One and two points")
    func tinyProblems() throws {
        let single = try solver.solve(TourProblem(costs: CostMatrix(rows: [[0]])))
        #expect(single.order == [0])
        #expect(single.cost == 0)

        let pair = try CostMatrix(rows: [[0, 4], [6, 0]])
        #expect(try solver.solve(TourProblem(costs: pair)).cost == 10)
        #expect(try solver.solve(TourProblem(costs: pair, start: 1, end: .anywhere)).order == [1, 0])
        #expect(try solver.solve(TourProblem(costs: pair, end: .at(1))).cost == 4)
    }

    @Test("All costs equal")
    func equalCosts() throws {
        let matrix = try CostMatrix(count: 10, values: Array(repeating: 5, count: 100))

        #expect(try solver.solve(TourProblem(costs: matrix)).cost == 50)
        #expect(try solver.solve(TourProblem(costs: matrix, end: .at(9))).cost == 45)
    }

    @Test("Finds the only feasible tour among forbidden edges")
    func forbiddenEdges() throws {
        // Only the cycle 0 → 3 → 1 → 4 → 2 → 0 is allowed.
        var rows = [[Double]](repeating: [Double](repeating: .infinity, count: 5), count: 5)
        for (from, to) in [(0, 3), (3, 1), (1, 4), (4, 2), (2, 0)] { rows[from][to] = 7 }
        let problem = try TourProblem(costs: CostMatrix(rows: rows))

        let solution = try solver.solve(problem)

        #expect(solution.order == [0, 3, 1, 4, 2])
        #expect(solution.cost == 35)
    }

    @Test("Reports a problem without any tour of finite cost")
    func noFeasibleTour() throws {
        let unreachable = try CostMatrix(rows: [
            [0, .infinity, .infinity],
            [1, 0, 1],
            [1, 1, 0],
        ])
        #expect(throws: TourSolverError.noFeasibleTour) {
            try solver.solve(TourProblem(costs: unreachable))
        }
        let open = try solver.solve(TourProblem(costs: unreachable, start: 1, end: .anywhere))
        #expect(open.cost == 2)
    }

    @Test("Rejects problems above the limit and accepts a raised one")
    func sizeLimit() throws {
        let sixteen = try TourProblem(costs: TestMatrices.random(count: 16, seed: 1))

        #expect(throws: TourSolverError.problemTooLarge(count: 16, maximum: 15)) {
            try solver.solve(sixteen)
        }
        #expect(throws: TourSolverError.problemTooLarge(count: 6, maximum: 5)) {
            try ExactSolver(maximumPointCount: 5).solve(TourProblem(costs: TestMatrices.random(count: 6, seed: 1)))
        }
        #expect(try ExactSolver(maximumPointCount: 16).solve(sixteen).stopReason == .optimal)
    }

    @Test("Cancelling the task stops the search with an error")
    func cancellation() async throws {
        let problem = try TourProblem(costs: TestMatrices.random(count: 15, seed: 3))
        let solver = self.solver
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try solver.solve(problem)
        }
        await #expect(throws: TourSolverError.cancelled) {
            try await task.value
        }
    }

    @Test("Usable through the TourSolver protocol")
    func protocolConformance() async throws {
        func solve(_ problem: TourProblem, with solver: some TourSolver) async throws(TourSolverError) -> Double {
            try await solver.solve(problem).cost
        }
        let problem = try TourProblem(costs: TestMatrices.random(count: 8, seed: 1), start: 2, end: .anywhere)

        #expect(try await solve(problem, with: solver) == solver.solve(problem).cost)
    }
}
