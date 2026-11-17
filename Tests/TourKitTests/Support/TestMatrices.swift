import Foundation

@testable import TourKit

/// Matrices and reference computations shared by the tests.
enum TestMatrices {
    /// A random asymmetric matrix with whole costs 60–1800 (seconds in pathly), the same as in pathly's tests.
    static func random(count: Int, seed: UInt64) -> CostMatrix {
        var generator = SplitMix64(seed: seed)
        var values = [Double](repeating: 0, count: count * count)
        for from in 0..<count {
            for to in 0..<count where from != to {
                values[from * count + to] = Double.random(in: 60...1800, using: &generator).rounded()
            }
        }
        return try! CostMatrix(count: count, values: values)
    }

    /// Points spread over a city of about 12 × 9 km. Travel times come from great-circle distances
    /// at 30 km/h with a random asymmetric surcharge of up to 30%, like one-way streets in a real matrix.
    static func city(count: Int, seed: UInt64) -> CostMatrix {
        var generator = SplitMix64(seed: seed)
        let points = (0..<count).map { _ in
            (
                latitude: Double.random(in: 50.00...50.10, using: &generator),
                longitude: Double.random(in: 19.85...20.02, using: &generator)
            )
        }
        var values = [Double](repeating: 0, count: count * count)
        for from in 0..<count {
            for to in 0..<count where from != to {
                let meters = greatCircleDistance(points[from], points[to])
                values[from * count + to] = meters / (30 / 3.6) * Double.random(in: 1.0...1.3, using: &generator)
            }
        }
        return try! CostMatrix(count: count, values: values)
    }

    /// The same matrix with every cost multiplied by `factor`.
    static func scaled(_ matrix: CostMatrix, by factor: Double) -> CostMatrix {
        try! CostMatrix(count: matrix.count, values: matrix.values.map { $0 * factor })
    }

    /// The cost of `order`, computed directly from the definition and independently of the library's code.
    static func referenceCost(of order: [Int], in problem: TourProblem) -> Double {
        var edges = Array(zip(order, order.dropFirst()))
        if problem.end == .returnToStart, let last = order.last {
            edges.append((last, problem.start))
        }
        return edges.reduce(0) { $0 + problem.costs[from: $1.0, to: $1.1] }
    }

    /// Whether `order` visits every point exactly once with the start and the end the problem requires.
    static func isValid(_ order: [Int], for problem: TourProblem) -> Bool {
        guard order.sorted() == Array(0..<problem.count), order.first == problem.start else { return false }
        if case .at(let end) = problem.end {
            return order.last == end
        }
        return true
    }

    /// The optimal cost, found by checking every order of the points between the fixed endpoints.
    static func bruteForceOptimum(_ problem: TourProblem) -> Double {
        var fixedEnd: Int?
        if case .at(let end) = problem.end { fixedEnd = end }
        var middle = (0..<problem.count).filter { $0 != problem.start && $0 != fixedEnd }
        var best = Double.infinity
        permute(&middle, from: 0) { order in
            let tour = [problem.start] + order + (fixedEnd.map { [$0] } ?? [])
            best = min(best, referenceCost(of: tour, in: problem))
        }
        return best
    }

    private static func permute(_ values: inout [Int], from start: Int, visit: ([Int]) -> Void) {
        guard start < values.count else { return visit(values) }
        for index in start..<values.count {
            values.swapAt(start, index)
            permute(&values, from: start + 1, visit: visit)
            values.swapAt(start, index)
        }
    }

    private static func greatCircleDistance(
        _ a: (latitude: Double, longitude: Double),
        _ b: (latitude: Double, longitude: Double)
    ) -> Double {
        let radians = Double.pi / 180
        let deltaLatitude = (b.latitude - a.latitude) * radians
        let deltaLongitude = (b.longitude - a.longitude) * radians
        let h =
            sin(deltaLatitude / 2) * sin(deltaLatitude / 2)
            + cos(a.latitude * radians) * cos(b.latitude * radians) * sin(deltaLongitude / 2) * sin(deltaLongitude / 2)
        return 2 * 6_371_000 * asin(min(1, sqrt(h)))
    }
}

/// Runs `body` with a cost table over the closed-tour working costs of `matrix`.
func withTable<Result>(_ matrix: CostMatrix, _ body: (CostTable) -> Result) -> Result {
    SearchProblem(try! TourProblem(costs: matrix)).withTable(body)
}

/// A deadline that passes after a given number of checks: a time limit without waiting.
final class CountdownDeadline: @unchecked Sendable {
    private let lock = NSLock()
    private var remainingChecks: Int

    init(checks: Int) {
        remainingChecks = checks
    }

    var deadline: Deadline {
        Deadline { [self] in
            lock.withLock {
                remainingChecks -= 1
                return remainingChecks < 0
            }
        }
    }
}
