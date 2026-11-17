/// The starting tour: from the start, always go to the cheapest point not yet visited.
///
/// The result is typically some ten to twenty percent above the optimum, but it takes O(n²)
/// and gives local search a good place to begin.
enum NearestNeighbor {
    /// The path `[start, …, end]` through every point of the table (`end == start` for a closed tour).
    static func tour(in table: CostTable, start: Int, end: Int) -> [Int] {
        var tour = [start]
        tour.reserveCapacity(table.count + 1)
        var visited = [Bool](repeating: false, count: table.count)
        visited[start] = true
        visited[end] = true

        var current = start
        let interiorCount = table.count - (start == end ? 1 : 2)
        for _ in 0..<interiorCount {
            var nearest = -1
            var nearestCost = Double.infinity
            for candidate in 0..<table.count where !visited[candidate] {
                let cost = table[current, candidate]
                // On equal costs the lower index wins, so the tour is repeatable.
                if cost < nearestCost || nearest == -1 {
                    nearest = candidate
                    nearestCost = cost
                }
            }
            visited[nearest] = true
            tour.append(nearest)
            current = nearest
        }

        tour.append(end)
        return tour
    }
}
