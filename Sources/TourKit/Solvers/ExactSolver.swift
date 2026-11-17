/// A solver that finds a proven optimal tour for small problems.
///
/// It uses the Held-Karp dynamic program, which takes O(n²·2ⁿ) time and about 9·n·2ⁿ⁻¹ bytes of memory
/// for `n` points. At the default limit of 15 points that is a few milliseconds and about 2 MB;
/// each extra point roughly doubles both, so 20 points take about 90 MB.
///
/// ```swift
/// let optimal = try ExactSolver().solve(problem)
/// optimal.stopReason  // .optimal
/// ```
///
/// The search runs on the calling thread. At the default limit it is short enough not to matter;
/// with a raised ``maximumPointCount`` call it from a background task. It checks for cancellation regularly.
public struct ExactSolver: TourSolver {
    /// The default largest number of points the solver accepts.
    public static let defaultMaximumPointCount = 15

    /// The largest number of points the solver accepts.
    public var maximumPointCount: Int

    /// Creates a solver.
    ///
    /// - Parameter maximumPointCount: The largest number of points the solver accepts.
    public init(maximumPointCount: Int = ExactSolver.defaultMaximumPointCount) {
        self.maximumPointCount = maximumPointCount
    }

    /// Finds an optimal tour.
    ///
    /// - Parameter problem: The costs, the start and where the tour ends.
    /// - Returns: An optimal tour with ``StopReason/optimal``.
    /// - Throws: ``TourSolverError/problemTooLarge(count:maximum:)`` when the problem has more than
    ///   ``maximumPointCount`` points, ``TourSolverError/cancelled`` when the current task is cancelled,
    ///   and ``TourSolverError/noFeasibleTour`` when every tour uses a forbidden edge.
    /// - Complexity: O(*n*²·2ⁿ) for *n* points.
    public func solve(_ problem: TourProblem) throws(TourSolverError) -> TourSolution {
        let started = ContinuousClock.now
        guard problem.count <= maximumPointCount else {
            throw .problemTooLarge(count: problem.count, maximum: maximumPointCount)
        }
        if Task.isCancelled { throw .cancelled }

        // Forbidden edges get a penalty above any feasible tour, so the optimum of the working costs
        // is feasible whenever a feasible tour exists.
        let search = SearchProblem(problem)
        let tour = try search.withTable { (table) throws(TourSolverError) -> [Int] in
            try HeldKarp.tour(in: table, start: search.start, end: search.end)
        }

        let order = search.order(of: tour)
        let cost = problem.cost(of: order)
        guard cost.isFinite else { throw .noFeasibleTour }

        return TourSolution(
            order: order,
            cost: cost,
            stopReason: .optimal,
            statistics: .init(initialCost: cost, completedRestarts: 0, elapsed: ContinuousClock.now - started)
        )
    }
}
