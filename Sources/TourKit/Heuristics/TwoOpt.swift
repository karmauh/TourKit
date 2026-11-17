/// The 2-opt move: reverse the points `tour[i...j]`.
///
/// For a symmetric matrix comparing the two boundary edges would be enough. With an asymmetric matrix
/// the reversed segment travels each of its inner edges the other way, so its **whole** cost changes.
/// The change is computed exactly but in O(1) from prefix sums of the costs forward (`t[k] → t[k+1]`)
/// and backward (`t[k+1] → t[k]`), rebuilt in O(n) after every applied move.
/// The first and the last element of the tour never move.
enum TwoOpt {
    /// Prefix sums: `forward[k]` is the cost of `t[0] → … → t[k]`,
    /// `backward[k]` the cost of the same edges travelled in the opposite direction.
    struct PrefixSums {
        var forward: [Double]
        var backward: [Double]

        init(tour: [Int], table: CostTable) {
            forward = [Double](repeating: 0, count: tour.count)
            backward = forward
            rebuild(tour: tour, table: table)
        }

        mutating func rebuild(tour: [Int], table: CostTable) {
            for position in 0..<(tour.count - 1) {
                forward[position + 1] = forward[position] + table[tour[position], tour[position + 1]]
                backward[position + 1] = backward[position] + table[tour[position + 1], tour[position]]
            }
        }
    }

    /// The cost change after reversing `tour[i...j]` (`1 ≤ i < j ≤ tour.count − 2`).
    /// A negative value is an improvement.
    @inline(__always)
    static func delta(_ tour: [Int], from i: Int, to j: Int, sums: PrefixSums, table: CostTable) -> Double {
        let before = tour[i - 1]
        let after = tour[j + 1]
        let first = tour[i]
        let last = tour[j]
        let oldCost = table[before, first] + (sums.forward[j] - sums.forward[i]) + table[last, after]
        let newCost = table[before, last] + (sums.backward[j] - sums.backward[i]) + table[first, after]
        return newCost - oldCost
    }

    /// One pass: for every segment start `i` picks the best end `j` and reverses the segment
    /// if that shortens the tour.
    ///
    /// - Parameters:
    ///   - tour: The tour to improve in place; its first and last elements stay.
    ///   - table: The working costs.
    ///   - threshold: The smallest cost decrease accepted as an improvement.
    ///   - shouldStop: As in ``OrOpt/improve(_:table:neighbors:threshold:shouldStop:)``.
    /// - Returns: `true` when the tour got shorter.
    /// - Throws: The error thrown by `shouldStop`.
    static func improve<Failure: Error>(
        _ tour: inout [Int],
        table: CostTable,
        threshold: Double,
        shouldStop: () throws(Failure) -> Bool
    ) throws(Failure) -> Bool {
        let lastStop = tour.count - 2
        guard lastStop >= 2 else { return false }
        var sums = PrefixSums(tour: tour, table: table)
        var improved = false

        for i in 1..<lastStop {
            if try shouldStop() { return improved }

            var bestDelta = -threshold
            var bestEnd = -1
            for j in (i + 1)...lastStop {
                let delta = delta(tour, from: i, to: j, sums: sums, table: table)
                if delta < bestDelta {
                    bestDelta = delta
                    bestEnd = j
                }
            }

            if bestEnd >= 0 {
                tour[i...bestEnd].reverse()
                sums.rebuild(tour: tour, table: table)
                improved = true
            }
        }
        return improved
    }
}
