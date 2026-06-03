# License notices for the OMOP sample

The sample data is the **`synthea-covid19-10k`** dataset: an OMOP CDM v5.3
synthetic dataset generated with [Synthea](https://github.com/synthetichealth/synthea)
(Apache License 2.0) and the [ETL-Synthea](https://github.com/OHDSI/ETL-Synthea)
pipeline, distributed by the OHDSI / darwin-eu community as a
[CDMConnector](https://darwin-eu.github.io/CDMConnector/) example dataset. It is
downloaded by `omop/scripts/setup.sh` from the public CDMConnector example-data
store.

The data is generated synthetically and contains no real patient information
(no PHI).

The dataset bundles the OMOP standardized vocabularies (SNOMED, RxNorm, LOINC,
and others) via the [OHDSI Athena](https://athena.ohdsi.org/) project. Concept
names are reproduced here for analytical readability under those vocabularies'
redistribution terms; please attribute OHDSI Athena and the individual source
vocabularies in any derivative work.

The Malloy semantic model (`omop.malloy`), the dataset configuration
(`omop_synthea_covid.malloy`), and the notebooks in this directory are released
under the same [MIT License](../LICENSE) as the rest of `malloy-samples`.
