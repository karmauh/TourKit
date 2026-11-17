# How the Heuristic Works

Follow the steps of ``HeuristicSolver``: construction, two local search moves and restarts.

## Overview

``HeuristicSolver`` is a multi-start local search:

```
problem ──► one path form ──► nearest neighbor ──► local search ──┐
                                                                  ▼
                       best tour ◄── keep if shorter ◄── local search ◄── double bridge
                                                          (repeat `restarts` times)
```

Every step works on the same form of the problem, so each move handles all three tour shapes and
forbidden edges without special cases.

### One form for every tour shape

Internally every tour is a path `[s, …, e]` whose first and last elements never move:

- A closed tour (``TourProblem/End/returnToStart``) is the path `[s, …, s]`.
- A tour with a fixed end (``TourProblem/End/at(_:)``) is the path `[s, …, e]`.
- An open tour (``TourProblem/End/anywhere``) is a closed tour on a copy of the costs whose column
  `s` is zero. Returning to the start is then free, so the shortest closed tour is the shortest open
  path followed by a free return, which is dropped from the result.

A forbidden edge (`Double.infinity`) becomes a finite penalty `(n + 1) · max + 1`, where `max` is the
largest finite cost. Any tour without forbidden edges is cheaper than one penalty, so the search
removes forbidden edges first. Keeping the penalty finite matters: with real infinities a move would
compute `inf − inf = NaN`, every comparison with `NaN` is false, and the search would skip exactly the
moves that remove a forbidden edge. If the best tour still uses a penalized edge, the solver throws
``TourSolverError/noFeasibleTour``.

### Construction: nearest neighbor

The first tour starts at `s` and always goes to the cheapest point not visited yet. It takes O(n²)
and lands some ten to twenty percent above the optimum, which is a good place for local search to
begin. On equal costs the lower index wins, so the result is repeatable.

### Local search

Local search applies two kinds of moves until neither shortens the tour. The examples below use a
closed tour through five points, `0 → 1 → 2 → 3 → 4 → 0`, and `c(a, b)` for the cost from `a` to `b`.

#### Or-opt: move a short segment

Or-opt takes a segment of one to three consecutive points and moves it elsewhere **without
reversing** it. Moving point `1` between `3` and `4`:

```
before:  0 → 1 → 2 → 3 → 4 → 0
after:   0 → 2 → 3 → 1 → 4 → 0

removed: c(0,1) + c(1,2) + c(3,4)
added:   c(0,2) + c(3,1) + c(1,4)
change = added − removed
```

Because the segment keeps its direction, its inner edges stay the same, and the change is exactly
three removed and three added edges, even when costs differ by direction. That is why Or-opt is the
main move for an asymmetric matrix.

Trying every place for every segment would take O(n²) per pass. Instead, a segment `first…last` is
tried only after one of the 12 cheapest predecessors of `first` or before one of the 12 cheapest
successors of `last`. A good move almost always joins points that are close, so these neighbor
lists cut the work to O(n) per pass while losing very little.

#### 2-opt: reverse a segment

2-opt reverses the points between two positions. Reversing `1 … 3`:

```
before:  0 → 1 → 2 → 3 → 4 → 0
after:   0 → 3 → 2 → 1 → 4 → 0

removed: c(0,1) + c(1,2) + c(2,3) + c(3,4)
added:   c(0,3) + c(3,2) + c(2,1) + c(1,4)
```

With symmetric costs only the two boundary edges would change. With asymmetric costs every inner
edge is now traveled the other way: if `c(1,2) = 5` but `c(2,1) = 40`, that edge alone adds 35. So
2-opt must count the whole segment. It still does so in O(1) per candidate, using two prefix sums
over the current tour:

- `forward[k]`: the cost of `t[0] → t[1] → … → t[k]`;
- `backward[k]`: the cost of the same edges traveled in the opposite direction.

The inner cost of `t[i] … t[j]` is `forward[j] − forward[i]` before the move and
`backward[j] − backward[i]` after it. The sums are rebuilt in O(n) only after a move is applied.

#### When a change counts as an improvement

A move is applied only when it lowers the cost by more than `10⁻⁹ ×` the largest working cost.
Without this threshold, rounding errors in long floating-point sums could make two moves look like
improvements of each other and the search would cycle forever.

### Restarts: double bridge

Local search stops in a local minimum: no single Or-opt or 2-opt move helps. To escape, the solver
cuts the inner points of the best tour into four pieces `A B C D` and swaps the middle two:

```
before:  s  A  B  C  D  e
after:   s  A  C  B  D  e
```

This double bridge reverses nothing, so it suits an asymmetric matrix, and no single move undoes it.
Local search then runs again from the kicked tour, and the result replaces the best tour only if it
is shorter. The default configuration does this 30 times. The cuts come from a seeded random
generator, so the same seed always gives the same tour.

## See Also

- <doc:ChoosingASolver>
- ``HeuristicSolver/Configuration-swift.struct``
