/// Local search: Or-opt and 2-opt in turn until neither shortens the tour or the search must stop.
enum LocalSearch {
    static func run<Failure: Error>(
        _ tour: inout [Int],
        table: CostTable,
        neighbors: NeighborLists? = nil,
        threshold: Double,
        shouldStop: () throws(Failure) -> Bool
    ) throws(Failure) {
        var improved = true
        while improved {
            if try shouldStop() { return }
            let movedSegments = try OrOpt.improve(
                &tour, table: table, neighbors: neighbors, threshold: threshold, shouldStop: shouldStop)
            let reversedSegments = try TwoOpt.improve(&tour, table: table, threshold: threshold, shouldStop: shouldStop)
            improved = movedSegments || reversedSegments
        }
    }
}
