# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-11-17

First public release.

### Added

- `CostMatrix`, `TourProblem` and `TourSolution` with validation and typed errors.
- `HeuristicSolver`: nearest neighbor construction, Or-opt and asymmetric 2-opt local search,
  double bridge restarts, a time limit and cancellation.
- `ExactSolver`: Held-Karp dynamic programming for proven optimal tours of up to 15 points by default.
- Closed tours, open tours, tours ending at a chosen point, and forbidden edges in both solvers.
- DocC documentation with articles on getting started, choosing a solver and the heuristic.
- `Benchmarks` package with a TSPLIB quality report and performance benchmarks. The TSPLIB files
  are downloaded by a script and verified with checksums instead of being stored in the repository.

[Unreleased]: https://github.com/karmauh/TourKit/compare/0.1.0...HEAD
[0.1.0]: https://github.com/karmauh/TourKit/releases/tag/0.1.0
