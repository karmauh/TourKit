import Testing

@testable import TourKit

@Suite("HeuristicSolver")
struct HeuristicSolverTests {
    let solver = HeuristicSolver()

    static let variants: [(start: Int, end: TourProblem.End)] = [
        (0, .returnToStart),
        (1, .returnToStart),
        (0, .anywhere),
        (1, .anywhere),
        (0, .at(1)),
        (1, .at(0)),
    ]

    @Test(
        "Every point exactly once, the right endpoints, a cost that matches the order",
        arguments: [2, 3, 10, 41, 80], variants.indices
    )
    func validOrder(count: Int, variant: Int) throws {
        let (start, end) = Self.variants[variant]
        let matrix = TestMatrices.random(count: count, seed: UInt64(count))
        let problem = try TourProblem(costs: matrix, start: start, end: end)

        let solution = try solver.solve(problem, deadline: .never)

        #expect(TestMatrices.isValid(solution.order, for: problem))
        #expect(solution.cost == TestMatrices.referenceCost(of: solution.order, in: problem))
        #expect(solution.stopReason == .completed)
    }

    @Test("Not worse than nearest neighbor alone", arguments: [10, 20, 30, 40, 50] as [UInt64])
    func notWorseThanConstruction(seed: UInt64) throws {
        let problem = try TourProblem(costs: TestMatrices.city(count: 60, seed: seed))
        let solution = try solver.solve(problem, deadline: .never)

        #expect(solution.cost <= solution.statistics.initialCost)
    }

    @Test("Multi-start is not worse than a single local search")
    func restartsHelp() throws {
        let problem = try TourProblem(costs: TestMatrices.city(count: 80, seed: 99))
        let single = HeuristicSolver(configuration: .init(restarts: 0))

        let withoutRestarts = try single.solve(problem, deadline: .never)
        let withRestarts = try solver.solve(problem, deadline: .never)

        #expect(withoutRestarts.statistics.completedRestarts == 0)
        #expect(withRestarts.statistics.completedRestarts == solver.configuration.restarts)
        #expect(withRestarts.cost <= withoutRestarts.cost)
    }

    @Test("Negative restarts behave like zero")
    func negativeRestarts() throws {
        let problem = try TourProblem(costs: TestMatrices.city(count: 30, seed: 3))
        let negative = try HeuristicSolver(configuration: .init(restarts: -5)).solve(problem, deadline: .never)
        let zero = try HeuristicSolver(configuration: .init(restarts: 0)).solve(problem, deadline: .never)

        #expect(negative.order == zero.order)
        #expect(negative.statistics.completedRestarts == 0)
    }

    @Test("The same problem and seed give the same tour; another seed may differ")
    func deterministic() throws {
        let problem = try TourProblem(costs: TestMatrices.city(count: 50, seed: 5))

        #expect(try solver.solve(problem, deadline: .never).order == solver.solve(problem, deadline: .never).order)
    }

    @Test("One and two points")
    func tinyProblems() throws {
        let single = try solver.solve(TourProblem(costs: CostMatrix(rows: [[0]])), deadline: .never)
        #expect(single.order == [0])
        #expect(single.cost == 0)

        let pair = try CostMatrix(rows: [[0, 4], [6, 0]])
        #expect(try solver.solve(TourProblem(costs: pair), deadline: .never).cost == 10)
        #expect(try solver.solve(TourProblem(costs: pair, start: 1, end: .anywhere), deadline: .never).order == [1, 0])
        #expect(try solver.solve(TourProblem(costs: pair, start: 1, end: .anywhere), deadline: .never).cost == 6)
        #expect(try solver.solve(TourProblem(costs: pair, end: .at(1)), deadline: .never).cost == 4)
    }

    @Test("All costs equal")
    func equalCosts() throws {
        let matrix = try CostMatrix(count: 20, values: Array(repeating: 5, count: 400))

        #expect(try solver.solve(TourProblem(costs: matrix), deadline: .never).cost == 100)
        #expect(try solver.solve(TourProblem(costs: matrix, end: .anywhere), deadline: .never).cost == 95)
    }

    @Test("Avoids forbidden edges that nearest neighbor runs into")
    func forbiddenEdges() throws {
        // Nearest neighbor follows the cheap chain 0→1→2→3→4 and then needs the forbidden edge 4→0.
        var rows = [[Double]](repeating: [Double](repeating: 10, count: 5), count: 5)
        for point in 0..<4 { rows[point][point + 1] = 1 }
        rows[4][0] = .infinity
        let problem = try TourProblem(costs: CostMatrix(rows: rows))

        let solution = try solver.solve(problem, deadline: .never)

        #expect(solution.statistics.initialCost == .infinity)
        #expect(solution.cost == TestMatrices.bruteForceOptimum(problem))
        #expect(solution.cost == 32)
    }

    @Test("Reports a problem without any tour of finite cost")
    func noFeasibleTour() throws {
        let unreachable = try CostMatrix(rows: [
            [0, .infinity, .infinity],
            [1, 0, 1],
            [1, 1, 0],
        ])
        #expect(throws: TourSolverError.noFeasibleTour) {
            try solver.solve(TourProblem(costs: unreachable), deadline: .never)
        }
        #expect(throws: TourSolverError.noFeasibleTour) {
            try solver.solve(TourProblem(costs: CostMatrix(rows: [[0, .infinity], [1, 0]])), deadline: .never)
        }
    }

    @Test("An open tour ignores forbidden edges back into the start")
    func openTourIgnoresReturnEdges() throws {
        let matrix = try CostMatrix(rows: [
            [0, 2, 3],
            [.infinity, 0, 1],
            [.infinity, 1, 0],
        ])
        let solution = try solver.solve(TourProblem(costs: matrix, end: .anywhere), deadline: .never)

        #expect(solution.order == [0, 1, 2])
        #expect(solution.cost == 3)
    }

    @Test("Scaling every cost by a power of two gives the same tour", arguments: [0x1p-30, 0x1p-10, 0x1p20, 0x1p40])
    func scaleInvariant(factor: Double) throws {
        let matrix = TestMatrices.city(count: 60, seed: 77)
        let original = try solver.solve(TourProblem(costs: matrix), deadline: .never)
        let scaled = try solver.solve(TourProblem(costs: TestMatrices.scaled(matrix, by: factor)), deadline: .never)

        #expect(scaled.order == original.order)
        #expect(scaled.cost == original.cost * factor)
    }

    @Test("After the time limit: the best valid tour so far, marked as stopped by the limit")
    func timeLimit() throws {
        let problem = try TourProblem(costs: TestMatrices.city(count: 150, seed: 8))
        let countdown = CountdownDeadline(checks: 20)

        let solution = try solver.solve(problem, deadline: countdown.deadline)

        #expect(solution.stopReason == .timeLimit)
        #expect(solution.statistics.completedRestarts == 0)
        #expect(TestMatrices.isValid(solution.order, for: problem))
        #expect(solution.cost <= solution.statistics.initialCost)
    }

    @Test("A deadline already passed returns the nearest neighbor tour")
    func expiredDeadline() throws {
        let problem = try TourProblem(costs: TestMatrices.random(count: 30, seed: 4))
        let solution = try solver.solve(problem, deadline: Deadline { true })

        #expect(solution.stopReason == .timeLimit)
        #expect(solution.cost == solution.statistics.initialCost)
    }

    @Test("Cancelling the task stops the search with an error")
    func cancellation() async throws {
        let problem = try TourProblem(costs: TestMatrices.city(count: 150, seed: 9))
        let solver = self.solver
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await solver.solve(problem)
        }
        await #expect(throws: TourSolverError.cancelled) {
            try await task.value
        }
    }

    @Test("The async version gives the same tour as the synchronous core")
    func asyncMatchesSync() async throws {
        let problem = try TourProblem(costs: TestMatrices.random(count: 20, seed: 2), start: 3, end: .at(7))

        let asynchronous = try await solver.solve(problem)
        let synchronous = try solver.solve(problem, deadline: .never)

        #expect(asynchronous.order == synchronous.order)
        #expect(asynchronous.cost == synchronous.cost)
        #expect(asynchronous.stopReason == synchronous.stopReason)
        #expect(asynchronous.statistics.initialCost == synchronous.statistics.initialCost)
        #expect(asynchronous.statistics.completedRestarts == synchronous.statistics.completedRestarts)
    }

    @Test("Usable through the TourSolver protocol")
    func protocolConformance() async throws {
        func solve(_ problem: TourProblem, with solver: some TourSolver) async throws(TourSolverError) -> [Int] {
            try await solver.solve(problem).order
        }
        let problem = try TourProblem(costs: TestMatrices.random(count: 8, seed: 1))

        #expect(try await solve(problem, with: solver) == solver.solve(problem, deadline: .never).order)
    }
}
