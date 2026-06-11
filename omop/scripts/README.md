# OMOP sample — data download

The OMOP sample uses **`synthea-covid19-10k`**: an OMOP CDM v5.3 synthetic dataset
of ~10,700 patients generated with [Synthea](https://github.com/synthetichealth/synthea)'s
COVID-19 module and the [ETL-Synthea](https://github.com/OHDSI/ETL-Synthea) pipeline,
distributed by the OHDSI / darwin-eu community as a
[CDMConnector](https://darwin-eu.github.io/CDMConnector/) example dataset.

This dataset has real demographic diversity (race/ethnicity), a populated
`death` table, and the full OMOP vocabulary — enough to build a realistic analysis example. 
It has no lab results (`measurement`/`observation` are empty).

We do **not** commit the data to this repo. Run the setup script once:

```bash
bash omop/scripts/setup.sh
```

## What the script does

1. Downloads `synthea-covid19-10k_5.3.zip` (~840 MB) from the CDMConnector
   example-data Azure blob (public, no account needed).
2. Extracts only the tables the Malloy model uses (the files are already Parquet,
   so there is no conversion step):

   ```
   person, condition_occurrence, drug_exposure, visit_occurrence,
   procedure_occurrence, observation_period, death, concept, vocabulary, domain
   ```

   The ~1 GB of vocabulary tables the sample never queries
   (`concept_ancestor`, `concept_relationship`, `concept_synonym`,
   `drug_strength`) and unused clinical tables are skipped.
3. Writes the Parquet files to `omop/data/` (gitignored). Footprint ~195 MB,
   dominated by the full `concept` table (kept so `vocabulary_explorer.malloynb`
   can search the real vocabulary).

## Regenerating from scratch

```bash
rm -rf omop/data
bash omop/scripts/setup.sh
```

## Requirements

- `curl` and `unzip` (standard on macOS/Linux). No Python, no Java.
