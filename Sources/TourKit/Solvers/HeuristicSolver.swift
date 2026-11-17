/// A fast solver that finds a very good tour, though not a proven optimal one.
///
/// 1. Construction: nearest neighbor from the start.
/// 2. Improvement: Or-opt (restricted to nearest-neighbor lists) and 2-opt in turn, until no move
///    shortens the tour.
/// 3. Multi-start: the best tour is perturbed with a double bridge move and improved again;
///    a better result replaces the best one.
///
/// The same problem and configuration always give the same tour, unless the time limit stops the search:
/// how far the search gets before the limit depends on the machine.
///
/// ```swift
/// var solver = HeuristicSolver()
/// solver.configuration.timeLimit = .milliseconds(500)
/// let solution = try await solver.solve(problem)
/// ```
public struct HeuristicSolver: TourSolver {
    /// Settings of the search.
    public struct Configuration: Sendable, Hashable {
        /// The time after which the best tour so far is returned, or `nil` for no limit.
        public var timeLimit: Duration?
        /// The number of restarts from a perturbed tour after the first local search.
        /// A negative value is treated as 0.
        public var restarts: Int
        /// The seed of the perturbations. The same seed gives the same tour.
        public var seed: UInt64

        /// Creates a configuration.
        ///
        /// - Parameters:
        ///   - timeLimit: The time after which the best tour so far is returned, or `nil` for no limit.
        ///   - restarts: The number of restarts from a perturbed tour.
        ///   - seed: The seed of the perturbations.
        public init(timeLimit: Duration? = .seconds(2), restarts: Int = 30, seed: UInt64 = 0x5EED) {
            self.timeLimit = timeLimit
            self.restarts = restarts
            self.seed = seed
        }
    }

    /// Settings of the search.
    public var configuration: Configuration

    /// Creates a solver.
    ///
    /// - Parameter configuration: Settings of the search.
    public init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }

    /// Finds a tour off the caller's actor, within ``Configuration/timeLimit``.
    ///
    /// - Parameter problem: The costs, the start and where the tour ends.
    /// - Returns: The best tour found, with ``StopReason/completed`` or ``StopReason/timeLimit``.
    /// - Throws: ``TourSolverError/cancelled`` when the task is cancelled,
    ///   ``TourSolverError/noFeasibleTour`` when every tour found uses a forbidden edge.
    @concurrent
    public func solve(_ problem: TourProblem) async throws(TourSolverError) -> TourSolution {
        try solve(problem, deadline: configuration.timeLimit.map { .after($0) } ?? .never)
    }

    /// Finds a tour on the calling thread, stopping at `deadline` instead of ``Configuration/timeLimit``.
    ///
    /// Checks the deadline and the cancellation of the current task between moves.
    ///
    /// - Parameters:
    ///   - problem: The costs, the start and where the tour ends.
    ///   - deadline: When to stop and return the best tour so far.
    /// - Returns: The best tour found, with ``StopReason/completed`` or ``StopReason/timeLimit``.
    /// - Throws: ``TourSolverError/cancelled`` when the current task is cancelled,
    ///   ``TourSolverError/noFeasibleTour`` when every tour found uses a forbidden edge. A feasible tour may
    ///   still exist when the forbidden edges leave very few of them.
    /// - Complexity: O(*n*²) per pass of local search, for *n* points.
    public func solve(_ problem: TourProblem, deadline: Deadline) throws(TourSolverError) -> TourSolution {
        let started = ContinuousClock.now
        let search = SearchProblem(problem)
        let threshold = search.improvementThreshold

        var timedOut = false
        let shouldStop = { () throws(TourSolverError) -> Bool in
            if Task.isCancelled { throw .cancelled }
            if !timedOut, deadline.hasExpired { timedOut = true }
            return timedOut
        }

        let (tour, initialTour, completedRestarts) = try search.withTable {
            (table) throws(TourSolverError) -> ([Int], [Int], Int) in
            let neighbors = NeighborLists(table: table)
            var best = NearestNeighbor.tour(in: table, start: search.start, end: search.end)
            let initialTour = best
            try LocalSearch.run(&best, table: table, neighbors: neighbors, threshold: threshold, shouldStop: shouldStop)
            var bestCost = TourCost.cost(of: best, in: table)

            var generator = SplitMix64(seed: configuration.seed)
            var completedRestarts = 0
            let restarts = max(0, configuration.restarts)
            // With up to 2 interior points local search already checks every order.
            let canPerturb = best.count - 2 >= 3
            while canPerturb, completedRestarts < restarts, !(try shouldStop()) {
                var candidate = Perturbation.doubleBridge(best, using: &generator)
                try LocalSearch.run(
                    &candidate, table: table, neighbors: neighbors, threshold: threshold, shouldStop: shouldStop)
                // Even an interrupted candidate is a valid tour, so it is worth comparing.
                let candidateCost = TourCost.cost(of: candidate, in: table)
                if candidateCost < bestCost - threshold {
                    best = candidate
                    bestCost = candidateCost
                }
                if !timedOut { completedRestarts += 1 }
            }
            return (best, initialTour, completedRestarts)
        }

        let order = search.order(of: tour)
        let cost = problem.cost(of: order)
        guard cost.isFinite else { throw .noFeasibleTour }

        return TourSolution(
            order: order,
            cost: cost,
            stopReason: timedOut ? .timeLimit : .completed,
            statistics: .init(
                initialCost: problem.cost(of: search.order(of: initialTour)),
                completedRestarts: completedRestarts,
                elapsed: ContinuousClock.now - started
            )
        )
    }
}
