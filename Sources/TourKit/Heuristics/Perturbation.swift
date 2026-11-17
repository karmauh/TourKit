/// Perturbations of a tour for the next start of local search (multi-start).
enum Perturbation {
    /// The double bridge move: interior points `A B C D` become `A C B D`; the endpoints stay.
    ///
    /// It swaps two adjacent pieces without reversing either, so it suits an asymmetric matrix.
    /// A single Or-opt or 2-opt move cannot easily undo it, which is why it leads the search out of
    /// a local minimum. Needs at least 2 interior points.
    static func doubleBridge(_ tour: [Int], using generator: inout some RandomNumberGenerator) -> [Int] {
        let stops = Array(tour.dropFirst().dropLast())
        guard stops.count >= 2 else { return tour }

        // Three different cuts in 0…n make B and C non-empty (A and D may be empty).
        var cuts = Set<Int>()
        while cuts.count < 3 {
            cuts.insert(Int.random(in: 0...stops.count, using: &generator))
        }
        let sorted = cuts.sorted()
        let (first, second, third) = (sorted[0], sorted[1], sorted[2])

        let reordered = stops[..<first] + stops[second..<third] + stops[first..<second] + stops[third...]
        return [tour[0]] + reordered + [tour[tour.count - 1]]
    }
}
