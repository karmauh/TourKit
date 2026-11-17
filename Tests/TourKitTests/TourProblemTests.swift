import Testing
import TourKit

@Suite("TourProblem")
struct TourProblemTests {
    let matrix: CostMatrix

    init() throws {
        matrix = try CostMatrix(rows: [
            [0, 12, 30, 25],
            [15, 0, 9, 20],
            [28, 11, 0, 7],
            [22, 18, 6, 0],
        ])
    }

    @Test("Defaults to a closed tour from point 0")
    func defaults() throws {
        let problem = try TourProblem(costs: matrix)

        #expect(problem.start == 0)
        #expect(problem.end == .returnToStart)
        #expect(problem.count == 4)
        #expect(problem.costs == matrix)
    }

    @Test(
        "Keeps valid tour variants",
        arguments: [
            (2, TourProblem.End.returnToStart),
            (2, .anywhere),
            (0, .at(3)),
            (3, .at(0)),
        ] as [(Int, TourProblem.End)]
    )
    func keepsVariant(start: Int, end: TourProblem.End) throws {
        let problem = try TourProblem(costs: matrix, start: start, end: end)

        #expect(problem.start == start)
        #expect(problem.end == end)
    }

    @Test("Stores an end at the start as a closed tour")
    func normalizesEndAtStart() throws {
        let problem = try TourProblem(costs: matrix, start: 2, end: .at(2))

        #expect(problem.end == .returnToStart)
    }

    @Test("Accepts a single point with every end variant")
    func singlePoint() throws {
        let single = try CostMatrix(rows: [[0]])

        #expect(try TourProblem(costs: single).end == .returnToStart)
        #expect(try TourProblem(costs: single, end: .anywhere).end == .anywhere)
        #expect(try TourProblem(costs: single, end: .at(0)).end == .returnToStart)
    }

    @Test("Rejects a start outside the matrix", arguments: [-1, 4, Int.max, Int.min])
    func rejectsStart(start: Int) {
        #expect(throws: TourProblemError.startOutOfRange(start: start, count: 4)) {
            try TourProblem(costs: matrix, start: start)
        }
    }

    @Test("Rejects an end outside the matrix", arguments: [-1, 4, Int.max])
    func rejectsEnd(end: Int) {
        #expect(throws: TourProblemError.endOutOfRange(end: end, count: 4)) {
            try TourProblem(costs: matrix, start: 0, end: .at(end))
        }
    }

    @Test("Checks the start before the end")
    func checksStartFirst() {
        #expect(throws: TourProblemError.startOutOfRange(start: 9, count: 4)) {
            try TourProblem(costs: matrix, start: 9, end: .at(9))
        }
    }
}
