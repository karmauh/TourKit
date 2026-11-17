/// The Or-opt move: move a segment of 1–3 consecutive points elsewhere in the tour, **without reversing** it.
///
/// The segment keeps its direction, so its inner cost does not change. The cost change is the difference
/// between three removed and three added edges, computed in O(1) even for an asymmetric matrix.
/// The first and the last element of the tour never move.
enum OrOpt {
    static let maxSegmentLength = 3

    /// The cost change after moving `tour[start..<start+length]` between positions `insertAfter`
    /// and `insertAfter + 1`. A negative value is an improvement.
    static func delta(
        _ tour: [Int],
        segmentStart start: Int,
        length: Int,
        insertAfter position: Int,
        table: CostTable
    ) -> Double {
        let first = tour[start]
        let last = tour[start + length - 1]
        return insertionCost(tour, first: first, last: last, after: position, table: table)
            - removalGain(tour, segmentStart: start, length: length, table: table)
    }

    /// Moves the segment to its new place. Positions refer to the tour before the move.
    static func apply(_ tour: inout [Int], segmentStart start: Int, length: Int, insertAfter position: Int) {
        let segment = Array(tour[start..<(start + length)])
        tour.removeSubrange(start..<(start + length))
        let insertionIndex = position < start ? position + 1 : position + 1 - length
        tour.insert(contentsOf: segment, at: insertionIndex)
    }

    /// One pass over all segments. Each segment goes to its best place if that shortens the tour.
    ///
    /// - Parameters:
    ///   - tour: The tour to improve in place; its first and last elements stay.
    ///   - table: The working costs.
    ///   - neighbors: When given, the segment `first…last` is inserted only after the nearest predecessors
    ///     of `first` or before the nearest successors of `last`; when `nil`, every place is checked.
    ///   - threshold: The smallest cost decrease accepted as an improvement.
    ///   - shouldStop: Called regularly; `true` ends the pass early (time limit), a thrown error cancels it.
    /// - Returns: `true` when the tour got shorter.
    /// - Throws: The error thrown by `shouldStop`.
    static func improve<Failure: Error>(
        _ tour: inout [Int],
        table: CostTable,
        neighbors: NeighborLists? = nil,
        threshold: Double,
        shouldStop: () throws(Failure) -> Bool
    ) throws(Failure) -> Bool {
        let lastStop = tour.count - 2
        guard lastStop >= 2 else { return false }
        let head = tour[0]
        let tail = tour[tour.count - 1]
        var positions = neighbors == nil ? [] : Self.positions(of: tour, pointCount: table.count)
        var improved = false

        for length in 1...min(maxSegmentLength, lastStop - 1) {
            for start in 1...(lastStop - length + 1) {
                if try shouldStop() { return improved }

                let gain = removalGain(tour, segmentStart: start, length: length, table: table)
                guard gain > threshold else { continue }
                let first = tour[start]
                let last = tour[start + length - 1]

                var bestDelta = -threshold
                var bestPosition = -1
                func consider(_ position: Int) {
                    guard position < start - 1 || position >= start + length else { return }
                    let delta = insertionCost(tour, first: first, last: last, after: position, table: table) - gain
                    if delta < bestDelta {
                        bestDelta = delta
                        bestPosition = position
                    }
                }

                if let neighbors {
                    // The endpoints sit outside `positions`. Inserting after the head means position 0 and
                    // inserting before the tail means the last stop; nothing can go after the tail of a path
                    // or before its head. In a closed tour head and tail are the same point.
                    for left in neighbors.predecessors[first] {
                        if left == head {
                            consider(0)
                        } else if left != tail {
                            consider(positions[left])
                        }
                    }
                    for right in neighbors.successors[last] {
                        if right == tail {
                            consider(lastStop)
                        } else if right != head {
                            consider(positions[right] - 1)
                        }
                    }
                } else {
                    for position in 0...lastStop { consider(position) }
                }

                if bestPosition >= 0 {
                    apply(&tour, segmentStart: start, length: length, insertAfter: bestPosition)
                    if neighbors != nil { positions = Self.positions(of: tour, pointCount: table.count) }
                    improved = true
                }
            }
        }
        return improved
    }

    /// `positions[point]`: the index of an interior point in the tour (meaningless for the endpoints).
    private static func positions(of tour: [Int], pointCount: Int) -> [Int] {
        var positions = [Int](repeating: 0, count: pointCount)
        for position in 1..<(tour.count - 1) {
            positions[tour[position]] = position
        }
        return positions
    }

    /// How much shorter the tour gets after cutting the segment out and joining its neighbors.
    @inline(__always)
    private static func removalGain(_ tour: [Int], segmentStart start: Int, length: Int, table: CostTable) -> Double {
        let previous = tour[start - 1]
        let next = tour[start + length]
        return table[previous, tour[start]] + table[tour[start + length - 1], next] - table[previous, next]
    }

    /// How much longer the tour gets after inserting the segment `first…last` after `position`.
    @inline(__always)
    private static func insertionCost(_ tour: [Int], first: Int, last: Int, after position: Int, table: CostTable)
        -> Double
    {
        let left = tour[position]
        let right = tour[position + 1]
        return table[left, first] + table[last, right] - table[left, right]
    }
}
