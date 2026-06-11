#!/usr/bin/env bash
# Download the OMOP sample dataset on demand.
#
# Uses the 'synthea-covid19-10k' dataset: an OMOP CDM v5.3 synthetic dataset of
# ~10,700 patients built with Synthea's COVID-19 module and ETL-Synthea, then
# distributed by the OHDSI/darwin-eu community as a CDMConnector example dataset.
# It includes real demographic diversity (race/ethnicity), a populated death
# table, and the full OMOP vocabulary. No PHI.
#
# The source is a single ~840 MB zip. Most of that is full OMOP vocabulary tables
# this sample never queries (concept_ancestor, concept_relationship, etc.), so we
# extract only the tables the Malloy model uses (~195 MB on disk). The files are
# already Parquet — no conversion step.
#
# Run once from the repo root:
#   bash omop/scripts/setup.sh
#
# Re-run after `rm -rf omop/data/` to regenerate.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

DATASET="synthea-covid19-10k"
URL="https://cdmconnectordata.blob.core.windows.net/cdmconnector-example-data/${DATASET}_5.3.zip"
WORK_DIR="$(mktemp -d -t omop-build-XXXXXX)"
trap 'rm -rf "$WORK_DIR"' EXIT

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl is required." >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "ERROR: unzip is required." >&2; exit 1; }

# Only the tables the Malloy model references. The remaining vocabulary tables
# (concept_ancestor/relationship/synonym, drug_strength) and unused clinical
# tables (provider, visit_detail, cost, payer_plan_period, ...) are skipped.
TABLES=(person condition_occurrence drug_exposure visit_occurrence \
        procedure_occurrence observation_period death \
        concept vocabulary domain)

mkdir -p omop/data
rm -f omop/data/*.parquet

echo "Downloading ${DATASET} (~840 MB) ..."
curl -fSL --retry 3 --retry-all-errors --retry-connrefused -o "$WORK_DIR/data.zip" "$URL"

echo "Extracting the ${#TABLES[@]} tables this sample uses ..."
MEMBERS=()
for t in "${TABLES[@]}"; do MEMBERS+=("${DATASET}/${t}.parquet"); done
unzip -oq "$WORK_DIR/data.zip" "${MEMBERS[@]}" -d "$WORK_DIR"

mv "$WORK_DIR/${DATASET}"/*.parquet omop/data/

echo ""
echo "Done. Files in omop/data/:"
du -sh omop/data/*.parquet | sort -h
echo ""
echo "Open omop/README.malloynb in VS Code and start exploring."
