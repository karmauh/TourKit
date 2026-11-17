# TourKit benchmarks

A separate Swift package, so that users of TourKit never download `package-benchmark` and its
dependencies. It depends on TourKit through `.package(path: "..")`, so it always measures the code in
this repository.

| Target | What it does |
|---|---|
| `BenchmarkSupport` | TSPLIB parser, the list of instances with best known values, random matrices |
| `TSPLIBReport` | Solution quality: prints a Markdown table for the TSPLIB instances |
| `TourKitBenchmarks` | Performance: time and allocations of `HeuristicSolver` on random matrices |
| `BenchmarkSupportTests` | Tests of the parser and of the data files |

Run every command below from this folder (`Benchmarks/`).

## Solution quality

The TSPLIB files are not stored in the repository. Download them once, then run the report:

```sh
Scripts/download-tsplib.sh
swift run -c release TSPLIBReport
```

The script checks every file against `Data/checksums.sha256` and skips files that are already there.
Without the files, the report stops with a message and the parser test of the instances is skipped.

The table compares `HeuristicSolver` with its default configuration against the best known tour
lengths of seven TSPLIB instances (see `Data/README.md`). An optional argument sets the number of
restarts, for example `swift run -c release TSPLIBReport 300`.

## Performance

```sh
swift package benchmark
```

On Swift 6.3 and later, `package-benchmark` counts allocations with its own `malloc-interposer`
package, so there is nothing to install. On Swift 6.2 and earlier it uses jemalloc instead, which
has to be installed first (`brew install jemalloc` on macOS, `libjemalloc-dev` on Debian and
Ubuntu); without it, set `BENCHMARK_DISABLE_JEMALLOC=true` and the allocation metric is missing.

Each benchmark solves one random matrix (50, 100, 150 and 200 points) with all restarts and no
time limit, so every iteration does the same work. The 150-point case is the size from the
two-second requirement.

### Reading the results

Every metric is a row with percentiles over all samples (iterations): `p50` is the median, `p0`
the fastest and `p100` the slowest run. Compare medians; a large gap between `p50` and `p99` means
noise from the machine, not from the code. `Malloc (total)` is the number of allocations in one
iteration and does not depend on the machine, so it is the most stable metric to compare. A `*`
marks metrics shown per inner iteration (`scaledIterations`); here the scaling factor is 1, so they
are per call of `solve`.

### Comparing two versions

```sh
git switch main
swift package --allow-writing-to-package-directory benchmark baseline update main
git switch my-branch
swift package benchmark baseline compare main
```

`baseline update` saves the results in `.benchmarkBaselines/` (ignored by Git), and `baseline
compare` prints the difference for every metric. To fail on a regression, for example in CI, use
`swift package benchmark baseline check main` instead.

## Why `Package.resolved` is committed here

TourKit is a library, so its `Package.resolved` is not committed: the app that uses TourKit
resolves the versions of all its dependencies, and a pinned file in the library would be ignored
anyway. This package is an end product, like an app. Committing its `Package.resolved` makes every
run use the same version of `package-benchmark` and its dependencies, so results from different
days and machines stay comparable.
