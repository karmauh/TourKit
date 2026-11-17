/// The Held-Karp dynamic program: the cheapest path `[start, …, end]` through every point.
///
/// Let the interior points be all points except the two endpoints. For every subset `S` of interior points
/// (a bit mask) and every `j` in `S`, `cost[S][j]` is the cheapest path that leaves `start`, visits exactly
/// the points of `S` and ends at `j`:
///
/// ```
/// cost[{j}][j] = c(start, j)
/// cost[S][j]   = min over k in S − {j} of cost[S − {j}][k] + c(k, j)
/// optimum      = min over j of cost[all][j] + c(j, end)
/// ```
///
/// Every subset is computed after all its smaller subsets because `S − {j} < S` as an integer.
/// Time O(m²·2ᵐ), memory 9·m·2ᵐ bytes for `m` interior points.
enum HeldKarp {
    /// The optimal path from `start` to `end` (equal for a closed tour) through every point of the table.
    ///
    /// - Throws: ``TourSolverError/cancelled`` when the current task is cancelled.
    static func tour(in table: CostTable, start: Int, end: Int) throws(TourSolverError) -> [Int] {
        let interior = (0..<table.count).filter { $0 != start && $0 != end }
        let m = interior.count
        guard m > 0 else { return [start, end] }
        precondition(m < Int(UInt8.max), "Too many points for the parent table")

        let stateCount = 1 << m
        var cost = [Double](repeating: .infinity, count: stateCount * m)
        // The previous interior point on the best path, or `noParent` for a path of one interior point.
        let noParent = UInt8.max
        var parent = [UInt8](repeating: noParent, count: stateCount * m)

        for j in 0..<m {
            cost[(1 << j) * m + j] = table[start, interior[j]]
        }

        for mask in 1..<stateCount {
            if mask & 0x3FF == 0, Task.isCancelled { throw .cancelled }
            // A single point: already set above.
            if mask & (mask - 1) == 0 { continue }

            var ends = mask
            while ends != 0 {
                let j = ends.trailingZeroBitCount
                ends &= ends - 1
                let previousMask = mask ^ (1 << j)

                var best = Double.infinity
                var bestPrevious = noParent
                var candidates = previousMask
                while candidates != 0 {
                    let k = candidates.trailingZeroBitCount
                    candidates &= candidates - 1
                    let value = cost[previousMask * m + k] + table[interior[k], interior[j]]
                    if value < best {
                        best = value
                        bestPrevious = UInt8(k)
                    }
                }
                cost[mask * m + j] = best
                parent[mask * m + j] = bestPrevious
            }
        }

        let full = stateCount - 1
        var best = Double.infinity
        var last = 0
        for j in 0..<m {
            let value = cost[full * m + j] + table[interior[j], end]
            if value < best {
                best = value
                last = j
            }
        }

        var reversedPath: [Int] = []
        reversedPath.reserveCapacity(m)
        var mask = full
        var current = last
        while true {
            reversedPath.append(interior[current])
            let previous = parent[mask * m + current]
            if previous == noParent { break }
            mask ^= 1 << current
            current = Int(previous)
        }
        return [start] + reversedPath.reversed() + [end]
    }
}
