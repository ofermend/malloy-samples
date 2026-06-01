#!/usr/bin/env bash
# Generate the OMOP sample dataset on demand.
#
# Downloads the OHDSI Eunomia GiBleed_5.3 dataset (~6.5 MB zip, ~25 MB
# unpacked) and converts the CSVs to ZSTD-compressed Parquet under
# omop/data/. Eunomia is a curated, OHDSI-distributed OMOP CDM v5.3
# sample dataset used in the official OHDSI tutorials.
#
# Run once from the repo root:
#   bash omop/scripts/setup.sh
#
# Re-run after `rm -rf omop/data/` if you want to regenerate.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

EUNOMIA_URL="https://raw.githubusercontent.com/OHDSI/EunomiaDatasets/main/datasets/GiBleed/GiBleed_5.3.zip"
WORK_DIR="$(mktemp -d -t omop-build-XXXXXX)"
trap 'rm -rf "$WORK_DIR"' EXIT

command -v curl >/dev/null 2>&1 || {
  echo "ERROR: curl is required." >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || {
  echo "ERROR: unzip is required." >&2; exit 1; }
command -v uv >/dev/null 2>&1 || command -v python3 >/dev/null 2>&1 || {
  echo "ERROR: python3 or uv is required for the Parquet conversion step." >&2; exit 1; }

mkdir -p omop/data

echo "Downloading Eunomia GiBleed 5.3 dataset ..."
curl -fSL --retry 3 --retry-all-errors --retry-connrefused -o "$WORK_DIR/eunomia.zip" "$EUNOMIA_URL"

echo "Unpacking ..."
unzip -q "$WORK_DIR/eunomia.zip" -d "$WORK_DIR"
CSV_DIR="$WORK_DIR/GiBleed_5.3"

if [[ ! -d "$CSV_DIR" ]]; then
  echo "ERROR: expected $CSV_DIR after unzip; found:" >&2
  ls -la "$WORK_DIR" >&2
  exit 1
fi

echo "Converting CSV → ZSTD Parquet ..."
if command -v uv >/dev/null 2>&1; then
  uv run --quiet omop/scripts/build_parquet.py \
    --source "$CSV_DIR" --target omop/data
else
  python3 -m pip install --quiet duckdb >/dev/null
  python3 omop/scripts/build_parquet.py \
    --source "$CSV_DIR" --target omop/data
fi

echo ""
echo "Done. Files in omop/data/:"
du -sh omop/data/*.parquet | sort -h
echo ""
echo "Open omop/README.malloynb in VS Code and start exploring."
