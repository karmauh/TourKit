import Testing

@testable import TourKit

@Suite("Or-opt and 2-opt")
struct ImproverTests {
    let matrix = TestMatrices.random(count: 12, seed: 3)
    let threshold = 1e-9

    /// A random closed tour from point 0 through every point of `matrix`.
    private func randomTour(_ generator: inout SplitMix64) -> [Int] {
        [0] + Array(1..<matrix.count).shuffled(using: &generator) + [0]
    }

    @Test("Or-opt: the O(1) cost change equals recomputing the whole tour")
    func orOptDeltaMatchesFullCost() {
        var generator = SplitMix64(seed: 11)
        withTable(matrix) { table in
            for _ in 0..<300 {
                let tour = randomTour(&generator)
                let lastStop = tour.count - 2
                let length = Int.random(in: 1...3, using: &generator)
                let start = Int.random(in: 1...(lastStop - length + 1), using: &generator)
                let allowed = (0...lastStop).filter { $0 < start - 1 || $0 >= start + length }
                let position = allowed.randomElement(using: &generator)!

                var moved = tour
                OrOpt.apply(&moved, segmentStart: start, length: length, insertAfter: position)
                let expected = TourCost.cost(of: moved, in: table) - TourCost.cost(of: tour, in: table)
                let delta = OrOpt.delta(tour, segmentStart: start, length: length, insertAfter: position, table: table)

                #expect(abs(delta - expected) < 1e-6)
                #expect(moved.sorted() == tour.sorted(), "The move neither loses nor duplicates points")
                #expect(moved.first == 0 && moved.last == 0)
            }
        }
    }

    @Test("Or-opt moves a segment without reversing it")
    func orOptKeepsDirection() {
        var tour = [0, 1, 2, 3, 4, 5, 0]
        OrOpt.apply(&tour, segmentStart: 1, length: 2, insertAfter: 4)
        #expect(tour == [0, 3, 4, 1, 2, 5, 0])
        OrOpt.apply(&tour, segmentStart: 3, length: 2, insertAfter: 0)
        #expect(tour == [0, 1, 2, 3, 4, 5, 0])
    }

    @Test("2-opt: the reversed segment cost from prefix sums equals recomputing the whole tour")
    func twoOptDeltaMatchesFullCost() {
        var generator = SplitMix64(seed: 12)
        withTable(matrix) { table in
            for _ in 0..<300 {
                let tour = randomTour(&generator)
                let lastStop = tour.count - 2
                let i = Int.random(in: 1..<lastStop, using: &generator)
                let j = Int.random(in: (i + 1)...lastStop, using: &generator)

                var reversed = tour
                reversed[i...j].reverse()
                let expected = TourCost.cost(of: reversed, in: table) - TourCost.cost(of: tour, in: table)
                let sums = TwoOpt.PrefixSums(tour: tour, table: table)
                let delta = TwoOpt.delta(tour, from: i, to: j, sums: sums, table: table)

                #expect(abs(delta - expected) < 1e-6)
            }
        }
    }

    @Test("2-opt is not fooled by an asymmetric matrix: the segment boundary alone is not enough")
    func twoOptUsesWholeSegmentCost() throws {
        // The boundary edges are as cheap after the reversal, but the segment 1→2→3 is cheap
        // only forward, so reversing it must come out worse.
        let matrix = try CostMatrix(rows: [
            [0, 5, 9, 1, 9],
            [9, 0, 1, 9, 9],
            [9, 100, 0, 1, 9],
            [9, 9, 100, 0, 5],
            [5, 9, 9, 9, 0],
        ])
        withTable(matrix) { table in
            let tour = [0, 1, 2, 3, 4, 0]
            let sums = TwoOpt.PrefixSums(tour: tour, table: table)
            // Boundary: (0→1) + (3→4) = 10 before, (0→3) + (1→4) = 10 after. A symmetric 2-opt
            // would see a change of 0; the true change is +198.
            #expect(TwoOpt.delta(tour, from: 1, to: 3, sums: sums, table: table) == 198)

            var improved = tour
            _ = TwoOpt.improve(&improved, table: table, threshold: threshold) { false }
            #expect(TourCost.cost(of: improved, in: table) <= TourCost.cost(of: tour, in: table))
        }
    }

    @Test(
        "No move makes the tour worse, and local search ends in a local minimum",
        arguments: [1, 2, 3, 4, 5] as [UInt64]
    )
    func neverWorsens(seed: UInt64) {
        var generator = SplitMix64(seed: seed)
        withTable(TestMatrices.random(count: 30, seed: seed)) { table in
            var tour = [0] + Array(1..<30).shuffled(using: &generator) + [0]
            var cost = TourCost.cost(of: tour, in: table)

            for _ in 0..<50 {
                _ = OrOpt.improve(&tour, table: table, threshold: threshold) { false }
                let afterOrOpt = TourCost.cost(of: tour, in: table)
                #expect(afterOrOpt <= cost + 1e-9)
                _ = TwoOpt.improve(&tour, table: table, threshold: threshold) { false }
                let afterTwoOpt = TourCost.cost(of: tour, in: table)
                #expect(afterTwoOpt <= afterOrOpt + 1e-9)
                cost = afterTwoOpt
            }

            LocalSearch.run(&tour, table: table, threshold: threshold) { false }
            #expect(!OrOpt.improve(&tour, table: table, threshold: threshold) { false })
            #expect(!TwoOpt.improve(&tour, table: table, threshold: threshold) { false })
            #expect(tour.dropLast().sorted() == Array(0..<30))
        }
    }

    @Test("Neighbor lists hold the K nearest in the direction of travel, and Or-opt with them never worsens")
    func neighborLists() {
        withTable(TestMatrices.city(count: 60, seed: 21)) { table in
            let neighbors = NeighborLists(table: table, size: 5)
            for node in 0..<60 {
                #expect(neighbors.successors[node].count == 5)
                #expect(!neighbors.successors[node].contains(node))
                let farthestListed = neighbors.successors[node].map { table[node, $0] }.max()!
                let closestOther = (0..<60).filter { $0 != node && !neighbors.successors[node].contains($0) }
                    .map { table[node, $0] }.min()!
                #expect(farthestListed <= closestOther)
                let farthestPredecessor = neighbors.predecessors[node].map { table[$0, node] }.max()!
                let closestOtherPredecessor = (0..<60)
                    .filter { $0 != node && !neighbors.predecessors[node].contains($0) }
                    .map { table[$0, node] }.min()!
                #expect(farthestPredecessor <= closestOtherPredecessor)
            }

            var generator = SplitMix64(seed: 22)
            var tour = [0] + Array(1..<60).shuffled(using: &generator) + [0]
            var cost = TourCost.cost(of: tour, in: table)
            for _ in 0..<20 {
                _ = OrOpt.improve(&tour, table: table, neighbors: neighbors, threshold: threshold) { false }
                let next = TourCost.cost(of: tour, in: table)
                #expect(next <= cost + 1e-9)
                cost = next
            }
            #expect(tour.dropLast().sorted() == Array(0..<60))
        }
    }

    @Test("On a path with two different endpoints the moves never touch the endpoints")
    func pathKeepsEndpoints() {
        withTable(TestMatrices.city(count: 40, seed: 31)) { table in
            let neighbors = NeighborLists(table: table)
            var generator = SplitMix64(seed: 32)
            for _ in 0..<20 {
                let middle = Array(1..<39).shuffled(using: &generator)
                var tour = [0] + middle + [39]
                let cost = TourCost.cost(of: tour, in: table)

                LocalSearch.run(&tour, table: table, neighbors: neighbors, threshold: threshold) { false }

                #expect(tour.first == 0 && tour.last == 39)
                #expect(tour.sorted() == Array(0..<40))
                #expect(TourCost.cost(of: tour, in: table) <= cost)
            }
        }
    }

    @Test("Tours with 0–2 interior points stay unchanged when nothing improves")
    func smallTours() throws {
        withTable(try CostMatrix(rows: [[0, 1, 1], [1, 0, 1], [1, 1, 0]])) { table in
            var empty = [0, 0]
            #expect(!OrOpt.improve(&empty, table: table, threshold: threshold) { false })
            #expect(!TwoOpt.improve(&empty, table: table, threshold: threshold) { false })
            var single = [0, 1, 0]
            #expect(!OrOpt.improve(&single, table: table, threshold: threshold) { false })
            #expect(!TwoOpt.improve(&single, table: table, threshold: threshold) { false })
            var pair = [0, 1, 2, 0]
            #expect(!TwoOpt.improve(&pair, table: table, threshold: threshold) { false })
            #expect(pair == [0, 1, 2, 0])
        }
    }
}
