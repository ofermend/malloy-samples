# /// script
# requires-python = ">=3.10"
# dependencies = ["duckdb>=1.0"]
# ///
"""Convert Eunomia OMOP CDM v5.3 CSV output to ZSTD Parquet.

Reads Eunomia's CSV files from --source and writes lowercase-column
ZSTD-compressed Parquet files to --target. Drops sparse / Eunomia-empty
tables and lowercases column names so the Malloy model can use
conventional lowercase identifiers.

Run from the repo root via omop/scripts/setup.sh.
"""

import argparse
import sys
from pathlib import Path

import duckdb

# Tables we ship. Eunomia GiBleed_5.3 contains the full OMOP CDM 5.3
# schema but several tables (visit_detail, specimen, provider, payer_plan_period,
# note, note_nlp, source_to_concept_map, cost) are essentially empty
# and add noise without value. concept_relationship has only 8 rows so we
# substitute concept_ancestor (~66 k rows) which is the table OHDSI
# tutorials actually query for "is descendant of concept" cohort logic.
TABLES = [
    "PERSON",
    "OBSERVATION_PERIOD",
    "VISIT_OCCURRENCE",
    "CONDITION_OCCURRENCE",
    "DRUG_EXPOSURE",
    "PROCEDURE_OCCURRENCE",
    "MEASUREMENT",
    "OBSERVATION",
    "DEATH",
    "CONCEPT",
    "CONCEPT_ANCESTOR",
    "VOCABULARY",
    "DOMAIN",
]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--source", required=True, type=Path,
                    help="Directory containing the unzipped GiBleed_5.3 CSVs")
    ap.add_argument("--target", required=True, type=Path,
                    help="Output directory for *.parquet files")
    args = ap.parse_args()

    src = args.source
    out_dir = args.target
    out_dir.mkdir(parents=True, exist_ok=True)

    missing = [t for t in TABLES if not (src / f"{t}.csv").exists()]
    if missing:
        print(f"ERROR: missing Eunomia CSVs: {missing}", file=sys.stderr)
        print(f"       expected under {src}", file=sys.stderr)
        return 1

    con = duckdb.connect()
    for t in TABLES:
        con.execute(
            f"CREATE VIEW {t.lower()} AS "
            f"SELECT * FROM read_csv_auto('{src / f'{t}.csv'}', header=true)"
        )

    # Sanity check: every concept_id referenced by a fact table should
    # resolve in CONCEPT. Eunomia is curated so this normally holds.
    orphans = con.execute(
        """
        SELECT COUNT(*) FROM condition_occurrence c
        LEFT JOIN concept k ON c.condition_concept_id = k.concept_id
        WHERE c.condition_concept_id IS NOT NULL
          AND c.condition_concept_id <> 0
          AND k.concept_id IS NULL
        """
    ).fetchone()[0]
    if orphans:
        print(
            f"WARN: {orphans} condition_occurrence rows reference unknown concept_id",
            file=sys.stderr,
        )

    for t in TABLES:
        lower = t.lower()
        # Lower-case every column name for a Malloy-friendly schema.
        cols = con.execute(f"PRAGMA table_info('{lower}')").fetchall()
        select_list = ", ".join(f'"{c[1]}" AS {c[1].lower()}' for c in cols)
        target = out_dir / f"{lower}.parquet"
        con.execute(
            f"COPY (SELECT {select_list} FROM {lower}) "
            f"TO '{target}' (FORMAT PARQUET, COMPRESSION ZSTD)"
        )
        rows = con.execute(f"SELECT COUNT(*) FROM {lower}").fetchone()[0]
        size_kb = max(1, target.stat().st_size // 1024)
        print(f"  {lower:25s} {rows:>8,d} rows  {size_kb:>6,d} KB")

    total = sum((out_dir / f"{t.lower()}.parquet").stat().st_size for t in TABLES)
    print(f"\nTotal: {total // 1024:,d} KB across {len(TABLES)} tables")
    return 0


if __name__ == "__main__":
    sys.exit(main())
