/// A type that finds a tour for a ``TourProblem``.
///
/// ``HeuristicSolver`` and ``ExactSolver`` conform, so code can accept either:
///
/// ```swift
/// func plan(_ problem: TourProblem, with solver: some TourSolver) async throws(TourSolverError) -> [Int] {
///     try await solver.solve(problem).order
/// }
/// ```
public protocol TourSolver: Sendable {
    /// Finds a tour that visits every point of the problem exactly once.
    ///
    /// - Parameter problem: The costs, the start and where the tour ends.
    /// - Returns: The tour with its cost and details of the search.
    /// - Throws: ``TourSolverError`` when the task is cancelled, no tour with a finite cost was found,
    ///   or the problem is too large for the solver.
    func solve(_ problem: TourProblem) async throws(TourSolverError) -> TourSolution
}
