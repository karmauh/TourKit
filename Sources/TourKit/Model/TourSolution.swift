/// Why a solver stopped and how good its tour is.
public enum StopReason: Sendable, Hashable {
    /// The tour is proven optimal.
    case optimal
    /// The solver finished all its planned work. The tour is a good one, but not proven optimal.
    case completed
    /// The time limit ran out. The tour is the best one found so far.
    case timeLimit
}

/// A tour found by a solver.
public struct TourSolution: Sendable, Hashable {
    /// Details of how the solver reached the tour.
    public struct Statistics: Sendable, Hashable {
        /// The cost of the first tour the solver built, before any improvement.
        public let initialCost: Double
        /// The number of restarts from a perturbed tour that ran to the end.
        public let completedRestarts: Int
        /// The time the solver spent.
        public let elapsed: Duration

        /// Creates statistics, for example for a custom ``TourSolver``.
        ///
        /// - Parameters:
        ///   - initialCost: The cost of the first tour, before any improvement.
        ///   - completedRestarts: The number of restarts that ran to the end.
        ///   - elapsed: The time the solver spent.
        public init(initialCost: Double, completedRestarts: Int, elapsed: Duration) {
            self.initialCost = initialCost
            self.completedRestarts = completedRestarts
            self.elapsed = elapsed
        }
    }

    /// Every point index exactly once, in visiting order.
    ///
    /// The order begins with the problem's start. With ``TourProblem/End/at(_:)`` it ends with that point.
    /// With ``TourProblem/End/returnToStart`` the start is not repeated at the end: the return is implied.
    public let order: [Int]
    /// The total cost of the tour, including the return edge for ``TourProblem/End/returnToStart``.
    public let cost: Double
    /// Why the solver stopped.
    public let stopReason: StopReason
    /// Details of how the solver reached the tour.
    public let statistics: Statistics

    /// Creates a solution, for example for a custom ``TourSolver``.
    ///
    /// The values are stored as given, without validation.
    ///
    /// - Parameters:
    ///   - order: Every point index exactly once, in visiting order.
    ///   - cost: The total cost of the tour.
    ///   - stopReason: Why the solver stopped.
    ///   - statistics: Details of how the solver reached the tour.
    public init(order: [Int], cost: Double, stopReason: StopReason, statistics: Statistics) {
        self.order = order
        self.cost = cost
        self.stopReason = stopReason
        self.statistics = statistics
    }
}
