# Choosing a Solver and Configuration

Pick between a proven optimum and a fast near-optimal tour, and tune the time limit and restarts.

## Overview

Both solvers conform to ``TourSolver``, so code that accepts `some TourSolver` works with either.
They differ in what they promise and in how far they scale.

| | ``ExactSolver`` | ``HeuristicSolver`` |
|---|---|---|
| Result | Proven optimum | Near-optimal tour |
| Practical size | Up to about 15 points | Hundreds of points |
| Time for 15 points | About a millisecond | Under a millisecond |
| Memory | Doubles with each point | Grows with n² |
| Runs on | The calling thread | A background thread (`async`) |
| ``TourSolution/stopReason`` | ``StopReason/optimal`` | ``StopReason/completed`` or ``StopReason/timeLimit`` |

### When to use the exact solver

Use ``ExactSolver`` when you need a guarantee, for example in tests that check another solver or for
small problems where every unit of cost matters. It refuses problems above
``ExactSolver/maximumPointCount`` with ``TourSolverError/problemTooLarge(count:maximum:)``
instead of running out of memory.

You can raise the limit, but each extra point roughly doubles the time and memory: 20 points take
about 90 MB. With a raised limit, call the solver from a background task, because it runs on the
calling thread.

```swift
let solver = ExactSolver(maximumPointCount: 17)
let solution = try await Task.detached { try solver.solve(problem) }.value
```

### When to use the heuristic solver

Use ``HeuristicSolver`` for everything else. On small problems it finds the optimum almost always:
compared with ``ExactSolver`` on 2,520 random instances of 4 to 10 points, it matched the optimum in
over 99% of them. On larger benchmark instances it usually stays within a few percent of the best
known tour; see the README for the full table.

### Tune the heuristic

``HeuristicSolver/Configuration-swift.struct`` has three settings:

- term ``HeuristicSolver/Configuration-swift.struct/timeLimit``: The longest the search may run,
  2 seconds by default, or `nil` for no limit. When it runs out, the solver returns the best tour
  found so far with ``StopReason/timeLimit``; it never throws because of time.
- term ``HeuristicSolver/Configuration-swift.struct/restarts``: How many times the search kicks
  the best tour and searches again, 30 by default. More restarts can find a shorter tour on large
  or irregular problems and take proportionally longer.
- term ``HeuristicSolver/Configuration-swift.struct/seed``: The seed of the random generator.
  The same problem, configuration and seed always give the same tour.

```swift
let solver = HeuristicSolver(configuration: .init(timeLimit: .milliseconds(200), restarts: 100))
let solution = try await solver.solve(problem)
```

With the default settings, 150 points take about 5 ms on an Apple M1 Pro, so the time limit is a
safety net rather than the usual way the search ends. Check
``TourSolution/Statistics-swift.struct/completedRestarts`` to see whether the limit cut the search
short.

### Control the deadline yourself

``HeuristicSolver/solve(_:)`` derives its deadline from the configuration. To share one deadline
between several solves or to stop on your own condition, call
``HeuristicSolver/solve(_:deadline:)`` with a ``Deadline``:

```swift
let deadline = Deadline.after(.seconds(1))
let morning = try solver.solve(morningProblem, deadline: deadline)
let evening = try solver.solve(eveningProblem, deadline: deadline)
```

This variant is synchronous and runs on the calling thread.

### Cancellation

Both solvers check `Task.isCancelled` while they search and throw ``TourSolverError/cancelled``
when the task is cancelled. The heuristic does not return a partial tour after cancellation; use a
time limit when you want the best tour found so far.

## See Also

- <doc:HowTheHeuristicWorks>
