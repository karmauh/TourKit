/// The nearest neighbors of every point, which restrict Or-opt to promising insertion places.
///
/// A good tour almost never reaches a point from far away, so a segment is worth inserting only next to
/// the points that are cheapest to come from or go to. Instead of `n` places Or-opt checks about `2K`:
/// after each of the `K` nearest predecessors of the segment and before each of the `K` nearest successors.
/// For 150 points that is several times less work at almost the same quality. For up to `K + 1` points
/// the lists cover every point, so the search is complete.
struct NeighborLists {
    static let defaultSize = 12

    /// `predecessors[v]`: the points from which `v` is cheapest to reach.
    let predecessors: [[Int]]
    /// `successors[v]`: the points cheapest to reach from `v`.
    let successors: [[Int]]

    init(table: CostTable, size: Int = defaultSize) {
        let nodes = Array(0..<table.count)
        predecessors = nodes.map { node in
            Array(nodes.filter { $0 != node }.sorted { table[$0, node] < table[$1, node] }.prefix(size))
        }
        successors = nodes.map { node in
            Array(nodes.filter { $0 != node }.sorted { table[node, $0] < table[node, $1] }.prefix(size))
        }
    }
}
