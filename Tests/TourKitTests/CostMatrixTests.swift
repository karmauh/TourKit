import Testing
import TourKit

@Suite("CostMatrix")
struct CostMatrixTests {
    @Test("Reads directed costs from rows")
    func readsRows() throws {
        let matrix = try CostMatrix(rows: [
            [0, 12, 30],
            [15, 0, 9],
            [28, 11, 0],
        ])

        #expect(matrix.count == 3)
        #expect(matrix[from: 0, to: 1] == 12)
        #expect(matrix[from: 1, to: 0] == 15)
        #expect(matrix[from: 2, to: 1] == 11)
    }

    @Test("Rows and a flat array describe the same matrix")
    func rowsMatchFlatValues() throws {
        let fromRows = try CostMatrix(rows: [[0, 1], [2, 0]])
        let fromValues = try CostMatrix(count: 2, values: [0, 1, 2, 0])

        #expect(fromRows == fromValues)
    }

    @Test("Ignores the diagonal and reads it as zero")
    func ignoresDiagonal() throws {
        let matrix = try CostMatrix(rows: [
            [9999, 4],
            [6, .nan],
        ])

        #expect(matrix[from: 0, to: 0] == 0)
        #expect(matrix[from: 1, to: 1] == 0)
        #expect(matrix == (try CostMatrix(rows: [[0, 4], [6, 0]])))
    }

    @Test("Accepts infinity as a forbidden edge, zero and negative zero")
    func acceptsSpecialValues() throws {
        let matrix = try CostMatrix(rows: [
            [0, .infinity, 0],
            [-0.0, 0, 3],
            [1, 2, 0],
        ])

        #expect(matrix[from: 0, to: 1] == .infinity)
        #expect(matrix[from: 0, to: 2] == 0)
        #expect(matrix[from: 1, to: 0] == 0)
    }

    @Test("A single point is a valid matrix")
    func singlePoint() throws {
        let matrix = try CostMatrix(rows: [[42]])

        #expect(matrix.count == 1)
        #expect(matrix[from: 0, to: 0] == 0)
    }

    @Test(
        "Rejects invalid rows",
        arguments: [
            ([], CostMatrixError.empty),
            ([[0, 1], [1]], .notSquare(row: 1, expectedCount: 2, actualCount: 1)),
            ([[0, 1, 2], [1, 0, 2]], .notSquare(row: 0, expectedCount: 2, actualCount: 3)),
            ([[]], .notSquare(row: 0, expectedCount: 1, actualCount: 0)),
            ([[0, .nan], [1, 0]], .notANumber(from: 0, to: 1)),
            ([[0, 1], [-2, 0]], .negativeCost(from: 1, to: 0, value: -2)),
            ([[0, -.infinity], [1, 0]], .negativeCost(from: 0, to: 1, value: -.infinity)),
        ] as [([[Double]], CostMatrixError)]
    )
    func rejectsInvalidRows(rows: [[Double]], expected: CostMatrixError) {
        #expect(throws: expected) {
            try CostMatrix(rows: rows)
        }
    }

    @Test(
        "Rejects invalid flat values",
        arguments: [
            (0, [], CostMatrixError.empty),
            (-1, [], .empty),
            (2, [0, 1, 2], .valueCountMismatch(expected: 4, actual: 3)),
            (1, [0, 1], .valueCountMismatch(expected: 1, actual: 2)),
            (.max, [0], .valueCountMismatch(expected: .max, actual: 1)),
        ] as [(Int, [Double], CostMatrixError)]
    )
    func rejectsInvalidValues(count: Int, values: [Double], expected: CostMatrixError) {
        #expect(throws: expected) {
            try CostMatrix(count: count, values: values)
        }
    }

    @Test("Reports the first invalid cost in row-major order")
    func reportsFirstInvalidCost() {
        #expect(throws: CostMatrixError.negativeCost(from: 0, to: 2, value: -1)) {
            try CostMatrix(rows: [
                [0, 1, -1],
                [.nan, 0, 1],
                [1, 1, 0],
            ])
        }
    }
}
