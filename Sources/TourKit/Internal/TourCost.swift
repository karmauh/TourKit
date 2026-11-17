/// Costs of tours in the search representation and in the public problem.
enum TourCost {
    /// The sum of the directed edges of `tour`, from its first to its last element.
    static func cost(of tour: [Int], in table: CostTable) -> Double {
        guard tour.count > 1 else { return 0 }
        var total = 0.0
        for position in 0..<(tour.count - 1) {
            total += table[tour[position], tour[position + 1]]
        }
        return total
    }
}

extension TourProblem {
    /// The cost of visiting `order` under this problem's original costs.
    ///
    /// Adds the return edge to the start for ``End/returnToStart`` only. Forbidden edges make the cost infinite.
    func cost(of order: [Int]) -> Double {
        guard let first = order.first, let last = order.last else { return 0 }
        var total = 0.0
        var previous = first
        for point in order.dropFirst() {
            total += costs[from: previous, to: point]
            previous = point
        }
        if end == .returnToStart {
            total += costs[from: last, to: start]
        }
        return total
    }
}
