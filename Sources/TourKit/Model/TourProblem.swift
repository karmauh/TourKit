/// A tour to plan: the costs, the point to start from and where the tour ends.
///
/// ```swift
/// let closed = try TourProblem(costs: matrix)                     // back to point 0
/// let open = try TourProblem(costs: matrix, start: 2, end: .anywhere)
/// let fixed = try TourProblem(costs: matrix, start: 0, end: .at(3))
/// ```
public struct TourProblem: Sendable, Equatable {
    /// Where a tour ends.
    public enum End: Sendable, Hashable {
        /// The tour returns to the start, and the cost of that last edge counts.
        case returnToStart
        /// The tour ends at whichever point is visited last, with no return edge.
        case anywhere
        /// The tour ends at the given point.
        ///
        /// A problem created with `.at(start)` stores ``returnToStart`` instead,
        /// because both describe the same tour.
        case at(Int)
    }

    /// The travel costs between all points.
    public let costs: CostMatrix
    /// The index of the first point of the tour.
    public let start: Int
    /// Where the tour ends.
    public let end: End

    /// The number of points, all of which the tour visits exactly once.
    public var count: Int { costs.count }

    /// Creates a problem and checks that its point indices fit the cost matrix.
    ///
    /// - Parameters:
    ///   - costs: The travel costs between all points.
    ///   - start: The index of the first point of the tour.
    ///   - end: Where the tour ends. `.at(start)` is stored as ``End/returnToStart``.
    /// - Throws: ``TourProblemError/startOutOfRange(start:count:)`` or
    ///   ``TourProblemError/endOutOfRange(end:count:)`` when an index is outside `0..<costs.count`.
    public init(costs: CostMatrix, start: Int = 0, end: End = .returnToStart) throws(TourProblemError) {
        let indices = 0..<costs.count
        guard indices.contains(start) else { throw .startOutOfRange(start: start, count: costs.count) }

        var end = end
        if case .at(let point) = end {
            guard indices.contains(point) else { throw .endOutOfRange(end: point, count: costs.count) }
            if point == start { end = .returnToStart }
        }

        self.costs = costs
        self.start = start
        self.end = end
    }
}
