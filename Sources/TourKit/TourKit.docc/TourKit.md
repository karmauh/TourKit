# ``TourKit``

Find short tours through points whose travel costs differ by direction.

## Overview

TourKit solves the asymmetric traveling salesman problem (ATSP): given the cost of traveling from
every point to every other point, it finds an order that visits each point once and keeps the total
cost low. The cost from `a` to `b` may differ from the cost from `b` to `a`, which is the usual case
for real travel times with one-way streets, turns and traffic.

The package has no dependencies, not even Foundation, and runs on iOS, macOS and Linux.

- ``HeuristicSolver`` finds a very good tour for hundreds of points in milliseconds.
- ``ExactSolver`` finds a proven optimal tour for up to about 15 points.

Both solvers handle closed tours, open tours and tours with a fixed last point, and both accept
forbidden edges.

## Topics

### Essentials

- <doc:GettingStarted>
- ``CostMatrix``
- ``TourProblem``
- ``TourSolution``

### Solvers

- <doc:ChoosingASolver>
- ``TourSolver``
- ``HeuristicSolver``
- ``ExactSolver``
- ``Deadline``
- ``StopReason``

### Algorithms

- <doc:HowTheHeuristicWorks>

### Errors

- ``CostMatrixError``
- ``TourProblemError``
- ``TourSolverError``
