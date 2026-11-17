/// Directed travel costs between every pair of points.
///
/// The cost of going from point `a` to point `b` may differ from the cost of going back,
/// so the matrix describes an asymmetric problem. Costs are in any unit you choose,
/// such as seconds or meters, as long as all of them use the same one.
///
/// - A cost of `Double.infinity` marks a forbidden edge.
/// - Values on the diagonal are ignored and read as `0`, so placeholders such as
///   `9999` used by TSPLIB files are accepted.
///
/// ```swift
/// let matrix = try CostMatrix(rows: [
///     [0, 12, 30],
///     [15, 0, 9],
///     [28, 11, 0],
/// ])
/// matrix[from: 0, to: 1]  // 12
/// ```
public struct CostMatrix: Sendable, Equatable {
    /// The number of points.
    public let count: Int

    /// Costs in row-major order: the cost from `a` to `b` is at `a * count + b`.
    let values: [Double]

    /// Creates a matrix from rows, where `rows[a][b]` is the cost from point `a` to point `b`.
    ///
    /// - Parameter rows: One row per point, each with one value per point.
    /// - Throws: ``CostMatrixError/empty`` when there are no rows,
    ///   ``CostMatrixError/notSquare(row:expectedCount:actualCount:)`` when a row has the wrong length,
    ///   and the errors listed in ``init(count:values:)`` for invalid costs.
    /// - Complexity: O(*n*²), where *n* is the number of points.
    public init(rows: [[Double]]) throws(CostMatrixError) {
        guard !rows.isEmpty else { throw .empty }
        for (index, row) in rows.enumerated() where row.count != rows.count {
            throw .notSquare(row: index, expectedCount: rows.count, actualCount: row.count)
        }
        try self.init(count: rows.count, values: Array(rows.joined()))
    }

    /// Creates a matrix from a flat array in row-major order.
    ///
    /// The cost from point `a` to point `b` is `values[a * count + b]`.
    ///
    /// - Parameters:
    ///   - count: The number of points.
    ///   - values: Exactly `count × count` costs.
    /// - Throws: ``CostMatrixError/empty`` when `count` is less than 1,
    ///   ``CostMatrixError/valueCountMismatch(expected:actual:)`` when `values` has the wrong length,
    ///   ``CostMatrixError/notANumber(from:to:)`` for a NaN cost,
    ///   and ``CostMatrixError/negativeCost(from:to:value:)`` for a negative cost.
    /// - Complexity: O(*n*²), where *n* is the number of points.
    public init(count: Int, values: [Double]) throws(CostMatrixError) {
        guard count >= 1 else { throw .empty }
        let (expected, overflow) = count.multipliedReportingOverflow(by: count)
        guard !overflow, expected == values.count else {
            throw .valueCountMismatch(expected: overflow ? .max : expected, actual: values.count)
        }

        var values = values
        for from in 0..<count {
            for to in 0..<count {
                let index = from * count + to
                if from == to {
                    values[index] = 0
                    continue
                }
                let value = values[index]
                if value.isNaN { throw .notANumber(from: from, to: to) }
                if value < 0 { throw .negativeCost(from: from, to: to, value: value) }
            }
        }
        self.count = count
        self.values = values
    }

    /// The cost of the edge from one point to another.
    ///
    /// - Parameters:
    ///   - from: The index of the point the edge leaves.
    ///   - to: The index of the point the edge enters.
    /// - Returns: The cost, `0` when `from == to`, or `Double.infinity` for a forbidden edge.
    /// - Precondition: Both indices are in `0..<count`.
    public subscript(from from: Int, to to: Int) -> Double {
        precondition(0 <= from && from < count && 0 <= to && to < count, "Point index out of range")
        return values[from * count + to]
    }
}
