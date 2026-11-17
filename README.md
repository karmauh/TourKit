# TourKit

[![CI](https://github.com/karmauh/TourKit/actions/workflows/ci.yml/badge.svg)](https://github.com/karmauh/TourKit/actions/workflows/ci.yml)

A Swift package that finds short tours through points whose travel costs differ by direction:
the asymmetric traveling salesman problem (ATSP).

- **Fast heuristic.** Hundreds of points in milliseconds, usually within a few percent of the best known tour.
- **Exact solver.** A proven optimum for up to about 15 points.
- **Three tour shapes.** Closed, open, or ending at a chosen point, plus forbidden edges.
- **No dependencies.** Not even Foundation. Runs on iOS 16, macOS 13 and Linux.
- **Swift 6.** Strict concurrency, typed throws, `Sendable` throughout.

## Installation

Add the package in Xcode with **File > Add Package Dependencies** and the URL
`https://github.com/karmauh/TourKit`, or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/karmauh/TourKit", .upToNextMinor(from: "0.1.0"))
],
targets: [
    .target(name: "MyApp", dependencies: ["TourKit"])
]
```

While TourKit is below 1.0, a minor version may contain breaking changes, so `.upToNextMinor` is the
safe range. In Xcode, choose **Up to Next Minor Version**.

## Example

```swift
import TourKit

// Row a, column b: the cost of traveling from a to b.
let costs = try CostMatrix(rows: [
    [0, 12, 30, 25],
    [14, 0, 18, 27],
    [28, 20, 0, 11],
    [24, 26, 13, 0],
])
let problem = try TourProblem(costs: costs, start: 0, end: .returnToStart)
let solution = try await HeuristicSolver().solve(problem)

solution.order  // [0, 1, 2, 3]
solution.cost   // 65.0
```

## Tour shapes

| `TourProblem.End` | Tour | Typical use |
|---|---|---|
| `.returnToStart` | Starts and ends at `start` | A delivery round from a depot |
| `.anywhere` | Starts at `start`, ends wherever is cheapest | A one-way trip |
| `.at(point)` | Starts at `start`, ends at `point` | From home to the office |

A cost of `Double.infinity` forbids an edge. If every tour uses a forbidden edge, the solver throws
`TourSolverError.noFeasibleTour`.

## Choosing a solver

| | `ExactSolver` | `HeuristicSolver` |
|---|---|---|
| Result | Proven optimum | Near-optimal tour |
| Practical size | Up to about 15 points | Hundreds of points |
| 150 random points (M1 Pro) | Not feasible | About 5 ms |

`HeuristicSolver` builds a nearest neighbor tour, improves it with Or-opt and an asymmetric 2-opt,
then restarts 30 times from double bridge perturbations. A 2-second time limit is a safety net: when
it runs out, the solver returns the best tour found so far.

## Quality on TSPLIB

Results of the default `HeuristicSolver` on the asymmetric instances from
[TSPLIB](https://comopt.ifi.uni-heidelberg.de/software/TSPLIB95/), measured on an Apple M1 Pro
with `swift run -c release TSPLIBReport` in [`Benchmarks/`](Benchmarks/README.md).

| Instance | Points | Best known | TourKit | Gap | Time |
|---|--:|--:|--:|--:|--:|
| br17 | 17 | 39 | 39 | 0.00 % | 0.4 ms |
| ftv33 | 34 | 1286 | 1286 | 0.00 % | 1.1 ms |
| p43 | 43 | 5620 | 5620 | 0.00 % | 1.0 ms |
| ftv64 | 65 | 1839 | 1891 | 2.83 % | 2.1 ms |
| ft70 | 70 | 38673 | 39601 | 2.40 % | 3.5 ms |
| kro124p | 100 | 36230 | 39722 | 9.64 % | 5.3 ms |
| rbg443 | 443 | 2720 | 2739 | 0.70 % | 26.4 ms |

Every run finished all 30 restarts well within the time limit. Against `ExactSolver` on 2,520 random
instances of 4 to 10 points, the heuristic matched the optimum in over 99% of them.

## Limitations

- **The heuristic gives no guarantee.** Most tours are optimal or close to it, but single instances can
  be far off: 9.6% on kro124p, and up to 30% on rare small random matrices. Use `ExactSolver` when a
  proven optimum matters and the problem is small enough.
- **The exact solver grows exponentially.** Each extra point roughly doubles its time and memory, so
  it refuses more than 15 points by default (20 points take about 90 MB).
- **One tour, no extra constraints.** Time windows, capacities and multiple vehicles are out of scope.

Possible directions after 0.1.0: let `HeuristicSolver` call the exact solver for small problems, and
adapt the number of restarts to the problem size.

## Documentation

The full documentation, with articles on choosing a solver and on how the heuristic works, is built
with DocC:

```bash
swift package generate-documentation --target TourKit
```

## Development

```bash
swift test
swift format lint --strict --recursive Package.swift Sources Tests
```

Benchmarks live in a separate package so that users of the library do not download their
dependencies; see [`Benchmarks/README.md`](Benchmarks/README.md).

## License

TourKit is available under the MIT license. See [LICENSE](LICENSE).
