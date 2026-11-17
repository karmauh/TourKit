/// A ``TourProblem`` reduced to the one shape the heuristic searches: a path `[start, …, end]`
/// whose two endpoints never move, over finite working costs.
///
/// - A closed tour is the path `[s, …, s]`.
/// - A tour with a fixed end is the path `[s, …, e]` over the original costs.
/// - An open tour is the closed path `[s, …, s]` with every edge into `s` free. Each closed tour enters `s`
///   exactly once, so its working cost equals the cost of the open path it starts with, and the cheapest
///   closed tour gives the cheapest open path.
///
/// Forbidden edges (`infinity`) get a finite penalty larger than the cost of any tour without them.
/// Infinite costs would make the moves compute `inf - inf = NaN`, and every comparison with `NaN` is false,
/// so the search would silently skip the very moves that remove a forbidden edge.
struct SearchProblem {
    let count: Int
    let start: Int
    /// The last element of every search tour: `start` for closed and open tours.
    let end: Int
    /// The smallest cost decrease accepted as an improvement. It scales with the costs, so floating-point
    /// rounding in large sums can never look like an improvement and make the search cycle.
    let improvementThreshold: Double
    private let values: [Double]

    /// The relative size of ``improvementThreshold``. Rounding errors in a tour sum are about
    /// `count × largest cost × 1e-16`, many orders of magnitude below this for any practical size.
    static let relativeImprovementThreshold = 1e-9

    init(_ problem: TourProblem) {
        let count = problem.count
        let start = problem.start
        var values = problem.costs.values

        switch problem.end {
        case .returnToStart:
            end = start
        case .anywhere:
            end = start
            for from in 0..<count {
                values[from * count + start] = 0
            }
        case .at(let point):
            end = point
        }

        var largestFinite = 0.0
        var hasForbiddenEdge = false
        for value in values {
            if value.isFinite {
                largestFinite = max(largestFinite, value)
            } else {
                hasForbiddenEdge = true
            }
        }

        var largest = largestFinite
        if hasForbiddenEdge {
            // A tour has at most `count` edges, so any tour without forbidden edges costs at most
            // `count × largestFinite`, which is less than one penalty.
            let penalty = (Double(count) + 1) * largestFinite + 1
            for index in values.indices where values[index].isInfinite {
                values[index] = penalty
            }
            largest = penalty
        }

        self.count = count
        self.start = start
        self.values = values
        self.improvementThreshold = largest * Self.relativeImprovementThreshold
    }

    /// Runs `body` with a ``CostTable`` over the working costs.
    func withTable<Result, Failure: Error>(
        _ body: (CostTable) throws(Failure) -> Result
    ) throws(Failure) -> Result {
        try values.withUnsafeBufferPointer { (buffer) throws(Failure) -> Result in
            try body(CostTable(count: count, values: buffer))
        }
    }

    /// The public visiting order for a search tour: without the repeated start of a closed path.
    func order(of tour: [Int]) -> [Int] {
        end == start ? Array(tour.dropLast()) : tour
    }
}
