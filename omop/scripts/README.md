# OMOP sample — data regeneration

The OMOP sample uses the [OHDSI Eunomia GiBleed_5.3](https://github.com/OHDSI/EunomiaDatasets/tree/main/datasets/GiBleed) dataset, a curated synthetic OMOP CDM v5.3 dataset (~2,700 patients) used in the official OHDSI tutorials.

We do **not** commit the data to this repo. Run the setup script once to generate it locally:

```bash
bash omop/scripts/setup.sh
```

## What the script does

1. Downloads `GiBleed_5.3.zip` (~6.5 MB) from the OHDSI `EunomiaDatasets` GitHub repository.
2. Unzips into a temporary directory.
3. Runs `build_parquet.py` to convert each CSV to ZSTD-compressed Parquet, lowercase column names, and drop tables that are empty in the Eunomia release.
4. Writes the Parquet files to `omop/data/` (gitignored).

## Tables produced

```
person, observation_period, visit_occurrence, condition_occurrence,
drug_exposure, procedure_occurrence, measurement, observation, death,
concept, concept_ancestor, vocabulary, domain
```

Total disk footprint is ~4 MB across 13 files.

## Regenerating from scratch

```bash
rm -rf omop/data
bash omop/scripts/setup.sh
```

## Requirements

- `curl` and `unzip` (standard on macOS/Linux)
- `python3` 3.10+ with `pip`, or [`uv`](https://docs.astral.sh/uv/) (the script auto-detects)

No Java required.

## Why Eunomia and not Synthea?

We considered generating data with [Synthea](https://github.com/synthetichealth/synthea), but the current Synthea releases do not include a native OMOP CDM exporter — converting Synthea output to OMOP requires the [ETL-Synthea](https://github.com/OHDSI/ETL-Synthea) R package or equivalent, which adds a heavy dependency. Eunomia is the canonical OHDSI-distributed sample for OMOP, pre-built and well-cited in the OHDSI community.
