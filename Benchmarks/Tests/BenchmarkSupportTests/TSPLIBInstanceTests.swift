import BenchmarkSupport
import Testing
import TourKit

@Suite("TSPLIB parser")
struct TSPLIBInstanceTests {
    let valid = """
        NAME: tiny
        TYPE: ATSP
        COMMENT: Three points (test)
        DIMENSION:  3
        EDGE_WEIGHT_TYPE : EXPLICIT
        EDGE_WEIGHT_FORMAT: FULL_MATRIX
        EDGE_WEIGHT_SECTION
         9999 1 2
         3 9999
           4 5 6 9999
        EOF
        """

    @Test("Reads the header and values split across lines in any way")
    func parsesValidFile() throws {
        let instance = try TSPLIBInstance(text: valid)

        #expect(instance.name == "tiny")
        #expect(instance.comment == "Three points (test)")
        #expect(instance.count == 3)
        #expect(instance.costs[from: 0, to: 2] == 2)
        #expect(instance.costs[from: 1, to: 0] == 3)
        #expect(instance.costs[from: 2, to: 1] == 6)
        #expect(instance.costs[from: 1, to: 1] == 0)
    }

    @Test(
        "Rejects unsupported or broken files",
        arguments: [
            ("TYPE: ATSP", "TYPE: TSP", TSPLIBInstance.ParseError.unsupported(field: "TYPE", value: "TSP")),
            (
                "EDGE_WEIGHT_FORMAT: FULL_MATRIX", "EDGE_WEIGHT_FORMAT: UPPER_ROW",
                .unsupported(field: "EDGE_WEIGHT_FORMAT", value: "UPPER_ROW")
            ),
            ("DIMENSION:  3", "DIMENSION: x", .invalidDimension("x")),
            ("DIMENSION:  3", "DIMENSION: 4", .wrongValueCount(expected: 16, actual: 9)),
            ("NAME: tiny\n", "", .missingField("NAME")),
            ("3 9999", "3 abc", .invalidNumber("abc")),
            ("3 9999", "-3 9999", .invalidMatrix(.negativeCost(from: 1, to: 0, value: -3))),
        ] as [(String, String, TSPLIBInstance.ParseError)]
    )
    func rejectsInvalidFile(original: String, replacement: String, expected: TSPLIBInstance.ParseError) {
        #expect(throws: expected) {
            try TSPLIBInstance(text: valid.replacingOccurrences(of: original, with: replacement))
        }
    }

    @Test(
        "Every benchmark instance parses with the expected size",
        .enabled(
            if: BenchmarkData.missingInstances.isEmpty,
            "TSPLIB files are missing; run \(BenchmarkData.downloadCommand) in the Benchmarks folder"
        ),
        arguments: BenchmarkData.instances.map(\.name)
    )
    func parsesBenchmarkInstances(name: String) throws {
        let expectedCounts = [
            "br17": 17, "ftv33": 34, "p43": 43, "ftv64": 65, "ft70": 70, "kro124p": 100, "rbg443": 443,
        ]
        let instance = try BenchmarkData.load(BenchmarkData.instances.first { $0.name == name }!)

        #expect(instance.name == name)
        #expect(instance.count == expectedCounts[name])
    }
}
