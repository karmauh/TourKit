# Getting Started

Add TourKit to your project and solve your first tour.

## Overview

You describe a problem in two steps: a ``CostMatrix`` with the travel costs, then a ``TourProblem``
that says where the tour starts and ends. A solver turns the problem into a ``TourSolution``.

### Add the package

In Xcode, choose **File > Add Package Dependencies** and enter the repository URL:

```
https://github.com/karmauh/TourKit
```

In a `Package.swift` manifest, add the package and the product:

```swift
dependencies: [
    .package(url: "https://github.com/karmauh/TourKit", from: "0.1.0")
],
targets: [
    .target(name: "MyApp", dependencies: ["TourKit"])
]
```

### Describe the costs

Each row of the matrix holds the costs of leaving one point. The value in row `a`, column `b` is the
cost of traveling from `a` to `b`. Use any unit, such as seconds or meters, as long as every value
uses the same one.

```swift
import TourKit

let costs = try CostMatrix(rows: [
    [0, 12, 30, 25],
    [14, 0, 18, 27],
    [28, 20, 0, 11],
    [24, 26, 13, 0],
])
```

The diagonal is ignored. A cost of `Double.infinity` forbids traveling along that edge.

### Choose the shape of the tour

``TourProblem`` takes the start point and one of three endings:

- ``TourProblem/End/returnToStart``: a closed tour that comes back to the start (the default).
- ``TourProblem/End/anywhere``: an open tour that may end at any point.
- ``TourProblem/End/at(_:)``: a tour that must end at the given point.

```swift
let problem = try TourProblem(costs: costs, start: 0, end: .returnToStart)
```

### Solve

``HeuristicSolver`` is the right choice for most problems:

```swift
let solution = try await HeuristicSolver().solve(problem)

solution.order  // [0, 1, 2, 3]
solution.cost   // 65.0
```

The ``TourSolution/order`` lists every point once. In a closed tour the return to the start is
implied, so `0` does not appear again at the end. The ``TourSolution/cost`` includes that return.

### Handle errors

Every throwing API in TourKit uses typed throws, so the compiler knows the exact error type:

- ``CostMatrix/init(rows:)`` throws ``CostMatrixError`` for an empty, non-square or negative matrix.
- ``TourProblem/init(costs:start:end:)`` throws ``TourProblemError`` when a point is out of range.
- A solver throws ``TourSolverError`` when it is cancelled, when every tour uses a forbidden edge,
  or when the problem is too large for ``ExactSolver``.

```swift
do {
    let solution = try await HeuristicSolver().solve(problem)
    show(solution)
} catch .noFeasibleTour {
    showMessage("Some points cannot be reached.")
} catch {
    // Only .cancelled and .problemTooLarge(count:maximum:) remain.
}
```

## See Also

- <doc:ChoosingASolver>
