import Foundation
import TourKit

/// An asymmetric TSP instance read from a TSPLIB file.
///
/// Supports what the ATSP instances of TSPLIB use: `TYPE: ATSP`, `EDGE_WEIGHT_TYPE: EXPLICIT`
/// and `EDGE_WEIGHT_FORMAT: FULL_MATRIX`. Diagonal values (9999, 100000000 and others) are passed on
/// unchanged, because ``CostMatrix`` ignores the diagonal.
public struct TSPLIBInstance: Sendable {
    /// The `NAME` field.
    public let name: String
    /// The `COMMENT` field, or an empty string.
    public let comment: String
    /// The costs from `EDGE_WEIGHT_SECTION`.
    public let costs: CostMatrix

    /// The number of points (`DIMENSION`).
    public var count: Int { costs.count }

    /// An error in a TSPLIB file.
    public enum ParseError: Error, Equatable, Sendable {
        /// A required header field is missing.
        case missingField(String)
        /// A header field has a value this parser does not support.
        case unsupported(field: String, value: String)
        /// `DIMENSION` is not a positive integer.
        case invalidDimension(String)
        /// A value in `EDGE_WEIGHT_SECTION` is not a number.
        case invalidNumber(String)
        /// `EDGE_WEIGHT_SECTION` has a different number of values than `DIMENSION²`.
        case wrongValueCount(expected: Int, actual: Int)
        /// The values do not form a valid ``CostMatrix``.
        case invalidMatrix(CostMatrixError)
    }

    /// Parses the text of a TSPLIB file.
    ///
    /// Header lines have the form `KEY: value` or `KEY : value`. The data section starts after
    /// `EDGE_WEIGHT_SECTION` and ends at `EOF` or at the end of the text; its numbers may be split
    /// across lines in any way.
    public init(text: String) throws(ParseError) {
        var fields: [String: String] = [:]
        var dataTokens: [Substring] = []
        var inData = false

        for line in text.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            if trimmed == "EOF" { break }
            if inData {
                dataTokens += line.split(whereSeparator: \.isWhitespace)
            } else if trimmed == "EDGE_WEIGHT_SECTION" {
                inData = true
            } else if let colon = trimmed.firstIndex(of: ":") {
                let key = trimmed[..<colon].trimmingCharacters(in: .whitespaces)
                let value = trimmed[trimmed.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                fields[key] = value
            }
        }

        func field(_ key: String) throws(ParseError) -> String {
            guard let value = fields[key] else { throw .missingField(key) }
            return value
        }
        func require(_ key: String, equals expected: String) throws(ParseError) {
            let value = try field(key)
            guard value == expected else { throw .unsupported(field: key, value: value) }
        }

        try require("TYPE", equals: "ATSP")
        try require("EDGE_WEIGHT_TYPE", equals: "EXPLICIT")
        try require("EDGE_WEIGHT_FORMAT", equals: "FULL_MATRIX")
        let dimensionText = try field("DIMENSION")
        guard let dimension = Int(dimensionText), dimension > 0 else { throw .invalidDimension(dimensionText) }
        guard inData else { throw .missingField("EDGE_WEIGHT_SECTION") }

        var values: [Double] = []
        values.reserveCapacity(dataTokens.count)
        for token in dataTokens {
            guard let value = Double(token) else { throw .invalidNumber(String(token)) }
            values.append(value)
        }
        guard values.count == dimension * dimension else {
            throw .wrongValueCount(expected: dimension * dimension, actual: values.count)
        }

        do {
            costs = try CostMatrix(count: dimension, values: values)
        } catch {
            throw .invalidMatrix(error)
        }
        name = try field("NAME")
        comment = fields["COMMENT"] ?? ""
    }

    /// Reads and parses a TSPLIB file.
    public init(contentsOf url: URL) throws {
        try self.init(text: String(contentsOf: url, encoding: .utf8))
    }
}
