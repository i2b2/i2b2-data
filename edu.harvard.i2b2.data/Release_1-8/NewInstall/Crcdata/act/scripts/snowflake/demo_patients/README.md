# ACT Demo Patients (Snowflake)

Synthetic demo data for the i2b2 **ACT** project on Snowflake — the ACT
equivalent of the `demo` project's sample patients. Other database platforms
ship demo patients for the `demo` project; the ACT project previously shipped
only ontology/concept data with no patients to query. This dataset fills that
gap for Snowflake.

## Contents

| File | Table | ~Rows |
|---|---|---|
| `PATIENT_DIMENSION.snappy.parquet` | PATIENT_DIMENSION | 500 |
| `PATIENT_MAPPING.snappy.parquet` | PATIENT_MAPPING | 1,000 (HIVE + ACT_DEMO sources) |
| `VISIT_DIMENSION.snappy.parquet` | VISIT_DIMENSION | ~2,800 |
| `ENCOUNTER_MAPPING.snappy.parquet` | ENCOUNTER_MAPPING | ~2,800 |
| `PROVIDER_DIMENSION.snappy.parquet` | PROVIDER_DIMENSION | 21 |
| `OBSERVATION_FACT.snappy.parquet` | OBSERVATION_FACT | ~21,000 |

A single `OBSERVATION_FACT` table carries all fact types, each using concept
codes verified to exist in the ACT ontology `CONCEPT_DIMENSION`:

- **Demographics** — `DEM|SEX:*`, `DEM|RACE:*`, `DEM|HISP:*` facts (also
  mirrored in `PATIENT_DIMENSION` columns: `SEX_CD`, `RACE_CD`,
  `AGE_IN_YEARS_NUM`, `BIRTH_DATE`, `VITAL_STATUS_CD`, ...)
- **Visits** — `VISIT|TYPE:*` and `VISIT|LENGTH:*` facts (mirrored in
  `VISIT_DIMENSION.INOUT_CD` / `LENGTH_OF_STAY`)
- **Diagnoses** — `ICD10CM:*` (17 chronic conditions correlated with age,
  plus acute conditions including `ICD10CM:U07.1` COVID-19)
- **Medications** — `RXNORM:*`, clinically correlated with the diagnoses
  (e.g. E11.9 → metformin, I10 → lisinopril, E78.5 → atorvastatin)
- **Procedures** — `CPT4:*` (E&M codes matched to visit type, ECG, imaging,
  colonoscopy, immunization administration)
- **Labs** — `LOINC:*` with numeric values (`VALTYPE_CD='N'`, `NVAL_NUM`,
  `UNITS_CD`), ranges correlated with the diagnoses
- **Immunizations** — `CVX:*` (flu, COVID) with `ICD10CM:Z23`

All rows have `SOURCESYSTEM_CD = 'ACT_DEMO'` and `UPLOAD_ID = 1`, so the
dataset can be identified and removed cleanly.

## Loading

The standard installer flow loads this automatically: with
`db.project=act` and `db.type=snowflake` in `db.properties`, the
`db_demodata_load_data` ant target unzips `crcdata_DEMO_PATIENTS.zip` into
this directory and runs `../load_demo_patients.sql` (CREATE STAGE → PUT →
COPY INTO). The script deletes any previous `ACT_DEMO` rows first, so
re-running is safe.

To load manually with snowsql, run the statements in
`../load_demo_patients.sql`, replacing `${basedir}` with the absolute path of
the `Crcdata` directory.

After loading, refresh totalnum counts (TOTALNUM / ontology `C_TOTALNUM`) if
you want patient counts displayed in the ontology tree.

## Regenerating

```sh
python3 generate_act_demo_patients.py [--patients 500] [--seed 20251020]
```

Requires `pyarrow`. The generator is deterministic for a given seed. After
regenerating, rebuild the zip from the parent `snowflake` directory (the
`demo_patients/` path prefix must be kept so the installer unzips the files
back into this directory):

```sh
cd .. && zip -FS crcdata_DEMO_PATIENTS.zip demo_patients/*.snappy.parquet
```
