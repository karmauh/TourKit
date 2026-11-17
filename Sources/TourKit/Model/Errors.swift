/// An error thrown when a ``CostMatrix`` is created from invalid data.
public enum CostMatrixError: Error, Sendable, Hashable {
    /// The matrix has no points.
    case empty
    /// A row has a different number of values than there are rows.
    ///
    /// - Parameters:
    ///   - row: The index of the first row with a wrong length.
    ///   - expectedCount: The number of values each row must have, equal to the number of rows.
    ///   - actualCount: The number of values in that row.
    case notSquare(row: Int, expectedCount: Int, actualCount: Int)
    /// A flat array does not hold `count × count` values.
    ///
    /// - Parameters:
    ///   - expected: The required number of values, or `Int.max` when `count × count` overflows.
    ///   - actual: The number of values passed.
    case valueCountMismatch(expected: Int, actual: Int)
    /// The cost of an edge is not a number.
    ///
    /// - Parameters:
    ///   - from: The index of the point the edge leaves.
    ///   - to: The index of the point the edge enters.
    case notANumber(from: Int, to: Int)
    /// The cost of an edge is negative, including negative infinity.
    ///
    /// - Parameters:
    ///   - from: The index of the point the edge leaves.
    ///   - to: The index of the point the edge enters.
    ///   - value: The rejected cost.
    case negativeCost(from: Int, to: Int, value: Double)
}

/// An error thrown when a ``TourProblem`` refers to points outside its cost matrix.
public enum TourProblemError: Error, Sendable, Hashable {
    /// The start index is not a valid point index.
    ///
    /// - Parameters:
    ///   - start: The rejected start index.
    ///   - count: The number of points in the cost matrix.
    case startOutOfRange(start: Int, count: Int)
    /// The fixed end index is not a valid point index.
    ///
    /// - Parameters:
    ///   - end: The rejected end index.
    ///   - count: The number of points in the cost matrix.
    case endOutOfRange(end: Int, count: Int)
}

/// An error thrown by a ``TourSolver``.
public enum TourSolverError: Error, Sendable, Hashable {
    /// The task running the solver was cancelled.
    case cancelled
    /// Every tour that satisfies the problem uses at least one forbidden edge.
    case noFeasibleTour
    /// The problem has more points than the solver accepts.
    ///
    /// - Parameters:
    ///   - count: The number of points in the problem.
    ///   - maximum: The largest number of points the solver accepts.
    case problemTooLarge(count: Int, maximum: Int)
}
