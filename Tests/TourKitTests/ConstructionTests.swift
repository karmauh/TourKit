import Testing

@testable import TourKit

@Suite("Tour cost, construction and perturbation")
struct ConstructionTests {
    /// Asymmetric: 0→1→2→0 costs 1 + 1 + 1, while 0→2→1→0 costs 10 + 10 + 10.
    let asymmetric = try! CostMatrix(rows: [
        [0, 1, 10],
        [10, 0, 1],
        [1, 10, 0],
    ])

    @Test("Cost follows directed edges, so a reversed tour costs differently")
    func asymmetricCost() throws {
        let problem = try TourProblem(costs: asymmetric)

        #expect(problem.cost(of: [0, 1, 2]) == 3)
        #expect(problem.cost(of: [0, 2, 1]) == 30)
        withTable(asymmetric) { table in
            #expect(TourCost.cost(of: [0, 2, 1, 0], in: table) == 30)
        }
    }

    @Test("Cost of each tour variant")
    func variantCost() throws {
        #expect(try TourProblem(costs: asymmetric, end: .anywhere).cost(of: [0, 2, 1]) == 20)
        #expect(try TourProblem(costs: asymmetric, end: .at(1)).cost(of: [0, 2, 1]) == 20)
        #expect(try TourProblem(costs: asymmetric).cost(of: [0]) == 0)
        #expect(try TourProblem(costs: try CostMatrix(rows: [[0, 7], [5, 0]])).cost(of: [0, 1]) == 12)
    }

    @Test("Nearest neighbor takes the cheapest edge in the direction of travel")
    func nearestNeighbor() throws {
        withTable(asymmetric) { table in
            #expect(NearestNeighbor.tour(in: table, start: 0, end: 0) == [0, 1, 2, 0])
        }
        let matrix = try CostMatrix(rows: [
            [0, 5, 2, 9],
            [5, 0, 1, 1],
            [2, 8, 0, 3],
            [9, 1, 3, 0],
        ])
        withTable(matrix) { table in
            // 0 → 2 (2), 2 → 3 (3), 3 → 1 (1), 1 → 0.
            #expect(NearestNeighbor.tour(in: table, start: 0, end: 0) == [0, 2, 3, 1, 0])
            // From 1: 1 → 2 (1), 2 → 0 (2); 3 is the fixed end.
            #expect(NearestNeighbor.tour(in: table, start: 1, end: 3) == [1, 2, 0, 3])
            #expect(NearestNeighbor.tour(in: table, start: 2, end: 2) == [2, 0, 1, 3, 2])
        }
    }

    @Test("Nearest neighbor covers every point, from one point to many")
    func nearestNeighborCoversAllPoints() throws {
        withTable(try CostMatrix(rows: [[0]])) { table in
            #expect(NearestNeighbor.tour(in: table, start: 0, end: 0) == [0, 0])
        }
        withTable(try CostMatrix(rows: [[0, 3], [4, 0]])) { table in
            #expect(NearestNeighbor.tour(in: table, start: 1, end: 0) == [1, 0])
        }
        withTable(TestMatrices.random(count: 40, seed: 1)) { table in
            let tour = NearestNeighbor.tour(in: table, start: 7, end: 7)
            #expect(tour.first == 7 && tour.last == 7)
            #expect(tour.dropLast().sorted() == Array(0..<40))
        }
    }

    @Test("Double bridge keeps every point and both endpoints", arguments: [(0, 0), (0, 13)])
    func doubleBridge(head: Int, tail: Int) {
        var generator = SplitMix64(seed: 7)
        let tour = [head] + Array(1...12) + [tail]
        for _ in 0..<100 {
            let perturbed = Perturbation.doubleBridge(tour, using: &generator)
            #expect(perturbed.first == head && perturbed.last == tail)
            #expect(perturbed.dropFirst().dropLast().sorted() == Array(1...12))
            #expect(perturbed != tour)
        }
    }

    @Test("SplitMix64 repeats for the same seed")
    func deterministicGenerator() {
        var first = SplitMix64(seed: 42)
        var second = SplitMix64(seed: 42)
        #expect((0..<5).map { _ in first.next() } == (0..<5).map { _ in second.next() })
    }
}

@Suite("Search problem reduction")
struct SearchProblemTests {
    let matrix = try! CostMatrix(rows: [
        [0, 4, 6],
        [3, 0, 2],
        [8, 5, 0],
    ])

    @Test("A closed tour keeps the costs and ends at the start")
    func closed() throws {
        let search = SearchProblem(try TourProblem(costs: matrix, start: 1))

        #expect(search.end == 1)
        search.withTable { table in
            #expect(table[2, 1] == 5)
        }
        #expect(search.order(of: [1, 0, 2, 1]) == [1, 0, 2])
    }

    @Test("An open tour makes every edge into the start free")
    func open() throws {
        let search = SearchProblem(try TourProblem(costs: matrix, start: 1, end: .anywhere))

        #expect(search.end == 1)
        search.withTable { table in
            #expect(table[0, 1] == 0)
            #expect(table[2, 1] == 0)
            #expect(table[0, 2] == 6)
        }
        #expect(search.order(of: [1, 0, 2, 1]) == [1, 0, 2])
    }

    @Test("A fixed end becomes the last point of a path")
    func fixedEnd() throws {
        let search = SearchProblem(try TourProblem(costs: matrix, start: 1, end: .at(2)))

        #expect(search.end == 2)
        #expect(search.order(of: [1, 0, 2]) == [1, 0, 2])
    }

    @Test("Forbidden edges get a penalty above the cost of any tour without them")
    func penalty() throws {
        let matrix = try CostMatrix(rows: [
            [0, .infinity, 6],
            [3, 0, 2],
            [8, .infinity, 0],
        ])
        let search = SearchProblem(try TourProblem(costs: matrix))

        search.withTable { table in
            // (3 points + 1) × largest finite cost 8 + 1.
            #expect(table[0, 1] == 33)
            #expect(table[2, 1] == 33)
            #expect(table[0, 2] == 6)
        }
        #expect(search.improvementThreshold == 33 * SearchProblem.relativeImprovementThreshold)
    }

    @Test("The improvement threshold scales with the costs")
    func threshold() throws {
        let small = SearchProblem(try TourProblem(costs: matrix))
        let large = SearchProblem(try TourProblem(costs: TestMatrices.scaled(matrix, by: 1e6)))

        #expect(small.improvementThreshold == 8e-9)
        #expect(abs(large.improvementThreshold / small.improvementThreshold - 1e6) < 1e-3)
    }
}
