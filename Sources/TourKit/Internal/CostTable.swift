/// A read-only view of a square cost matrix for the hot path of the search.
///
/// The heuristic reads costs hundreds of thousands of times, so it indexes the matrix's contiguous
/// storage through a raw buffer pointer: no bounds-checked `Array` access, no retain/release, no copy.
/// The pointer is valid only inside `SearchProblem.withTable`, which is the only place that creates a table,
/// and no table escapes that closure.
struct CostTable {
    let count: Int
    private let values: UnsafeBufferPointer<Double>

    init(count: Int, values: UnsafeBufferPointer<Double>) {
        precondition(values.count == count * count, "Cost table must hold count × count values")
        self.count = count
        self.values = values
    }

    /// The cost of the directed edge `from → to`.
    @inline(__always)
    subscript(from: Int, to: Int) -> Double {
        values[from &* count &+ to]
    }
}
