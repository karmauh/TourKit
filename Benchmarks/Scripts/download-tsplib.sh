#!/bin/sh
# Downloads the TSPLIB instances used by the quality report into Benchmarks/Data.
#
# The files are not stored in the repository because TSPLIB states no terms of
# redistribution. Each file is checked against Data/checksums.sha256, so the report
# always runs on exactly the files the README table was measured on.
#
# Usage: Scripts/download-tsplib.sh   (from the Benchmarks folder or anywhere else)

set -eu

BASE_URL="https://comopt.ifi.uni-heidelberg.de/software/TSPLIB95/atsp"
DATA_DIR="$(cd "$(dirname "$0")/../Data" && pwd)"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

# check LINE: verifies one "<hash>  <file>" line relative to the current folder. The line goes
# through a file and short options only, because the BSD sha256sum on macOS reads no checksums
# from standard input and has no --check or --status.
check() {
    echo "$1" > "$TEMP_DIR/expected.sha256"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum -c "$TEMP_DIR/expected.sha256" >/dev/null 2>&1
    else
        shasum -a 256 -c "$TEMP_DIR/expected.sha256" >/dev/null 2>&1
    fi
}

cd "$DATA_DIR"
while read -r expected file; do
    line="$expected  $file"
    if [ -f "$file" ] && check "$line"; then
        echo "ok        $file"
        continue
    fi
    # The server is sometimes slow or briefly unreachable: give up on a connection after
    # 30 s and try again, instead of waiting minutes for a single attempt.
    curl --fail --silent --show-error --location \
        --connect-timeout 30 --max-time 120 --retry 3 --retry-delay 10 \
        --output "$TEMP_DIR/$file.gz" "$BASE_URL/$file.gz"
    gunzip --stdout "$TEMP_DIR/$file.gz" > "$TEMP_DIR/$file"
    if ! (cd "$TEMP_DIR" && check "$line"); then
        echo "error: $file does not match its checksum in Data/checksums.sha256" >&2
        exit 1
    fi
    mv "$TEMP_DIR/$file" "$file"
    echo "fetched   $file"
done < checksums.sha256
