# Benchmark data

Seven asymmetric TSP instances from **TSPLIB**, the library of travelling salesman problems
maintained by Gerhard Reinelt at Heidelberg University.

- Source: <https://comopt.ifi.uni-heidelberg.de/software/TSPLIB95/atsp/>
  (`<name>.atsp.gz`, unpacked; the files are unchanged).
- Checked on: 2026-11-17.
- Licence: the TSPLIB pages do not state any terms of use or redistribution, so the files are
  **not stored in this repository**. Download them with `Scripts/download-tsplib.sh`, which
  verifies each file against `checksums.sha256`. A mismatch means the file on the server changed
  and the results would no longer be comparable with the README table.

All files use `TYPE: ATSP`, `EDGE_WEIGHT_TYPE: EXPLICIT` and `EDGE_WEIGHT_FORMAT: FULL_MATRIX`.
The diagonal holds a placeholder (9999, 9999999, 100000000 or 0), which TourKit ignores.

## Best known tour lengths

From the TSPLIB page "Best known solutions for asymmetric TSPs" (`ATSP-BEST.html`, checked on
2026-11-17). The page lists kro124p as `kro124`.

| Instance | Points | Best known |
|---|--:|--:|
| br17 | 17 | 39 |
| ftv33 | 34 | 1286 |
| p43 | 43 | 5620 |
| ftv64 | 65 | 1839 |
| ft70 | 70 | 38673 |
| kro124p | 100 | 36230 |
| rbg443 | 443 | 2720 |

The same values are in `Sources/BenchmarkSupport/BenchmarkData.swift`, which the quality report uses.
