/// The moment a solver must stop and return its best tour so far.
///
/// The check is a closure, so tests can inject their own clock and exercise a time limit without waiting:
///
/// ```swift
/// let solution = try HeuristicSolver().solve(problem, deadline: Deadline { true })
/// solution.stopReason  // .timeLimit
/// ```
public struct Deadline: Sendable {
    private let check: @Sendable () -> Bool

    /// Creates a deadline from a check that the solver calls between moves.
    ///
    /// - Parameter check: Returns `true` once the deadline has passed. It is called often, so keep it cheap.
    public init(hasExpired check: @escaping @Sendable () -> Bool) {
        self.check = check
    }

    /// Whether the deadline has passed.
    public var hasExpired: Bool { check() }

    /// A deadline that passes the given duration from now, measured with `ContinuousClock`.
    ///
    /// - Parameter duration: The time from now until the deadline.
    /// - Returns: A deadline that expires once `duration` has elapsed.
    public static func after(_ duration: Duration) -> Deadline {
        let end = ContinuousClock.now.advanced(by: duration)
        return Deadline { ContinuousClock.now >= end }
    }

    /// A deadline that never passes.
    public static let never = Deadline { false }
}
