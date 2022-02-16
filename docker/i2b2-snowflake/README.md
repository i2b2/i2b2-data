# i2b2-snowflake

Provisioning and data-installation scripts for running i2b2 on **Snowflake**.

> **Snowflake is a cloud service.** Unlike `i2b2-oracle`, `i2b2-mssql` and
> `i2b2-pgsql`, there is no local database container to start or commit. These
> scripts connect to a **remote Snowflake account**, create the required
> objects, and load the i2b2 demo/ACT data. The data lives in Snowflake, not in
> a docker image.

## Contents

| File | Purpose |
|------|---------|
| `snowsight_admin_setup.sql` | **Run once in the Snowflake app (Snowsight) as ACCOUNTADMIN.** Creates the **role**, **warehouse**, **database**, the six i2b2 **schemas**, the **service user** (key-pair auth), and all **grants**. |
| `db.properties` | Connection template (key-pair auth); the orchestrator generates the real per-cell file from it. |
| `create_snowflake_image.sh` | Orchestrator: loads every cell via the ant data installer, connecting as the service user. Does **not** need ACCOUNTADMIN. |

## Two-step split

1. **Admin (once, in Snowsight):** an ACCOUNTADMIN runs `snowsight_admin_setup.sql`.
2. **Data load (repeatable, automated):** anyone with the service user's private key runs `create_snowflake_image.sh`.

## Authentication

The functional user is a Snowflake **`TYPE = SERVICE`** account using **key-pair (RSA) auth** — no password. Generate a key pair before running the admin script:

```bash
# private key (encrypted; omit -v2 aes-256-cbc for an unencrypted key)
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -v2 aes-256-cbc
# public key
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
# value to paste into RSA_PUBLIC_KEY in snowsight_admin_setup.sql
grep -v -- '-----' rsa_key.pub | tr -d '\n'
```

## Object model

One database (`I2B2_DEV` by default) with one schema per i2b2 cell:

| Cell | Schema |
|------|--------|
| Metadata (ontology) | `I2B2METADATA` |
| CRC / data mart | `I2B2DATA` |
| Hive | `I2B2HIVE` |
| Identity management | `I2B2IMDATA` |
| Project management | `I2B2PM` |
| Workplace | `I2B2WORKDATA` |

All cells connect as the same user/role and differ only by schema.

## Usage

**Step 1 — provision (Snowsight, as ACCOUNTADMIN):** paste your public key into
`snowsight_admin_setup.sql` and run it in a Snowsight worksheet.

**Step 2 — load data:**

```bash
export SNOWFLAKE_ACCOUNT=abc12345.us-east-2.aws
export I2B2_PRIVATE_KEY_FILE=/path/to/rsa_key.p8

# optional overrides (defaults shown) -- must match snowsight_admin_setup.sql
export I2B2_ROLE=I2B2
export I2B2_WAREHOUSE=I2B2_ETL_WH
export I2B2_DB=I2B2_DEV
export I2B2_USER=I2B2
export I2B2_PRIVATE_KEY_PWD=          # only if rsa_key.p8 is encrypted

bash create_snowflake_image.sh
```

The data load connects as the service user via key-pair auth and never needs
ACCOUNTADMIN.

## Notes

- **Stages / bulk load.** The ACT ontology and concept loaders create an internal
  `PARQUET_STAGE` and a `PARQUET_FORMAT` file format, `PUT` the `*.snappy.parquet`
  files to the stage, then `COPY INTO` the tables. `snowsight_admin_setup.sql`
  grants the role stage + file-format privileges (create, plus access to all/
  future stages and file formats) so these run.
- **`PUT` file path.** `load_concepts.sql` and `load_act_ont.sql` `PUT` from
  `${basedir}/act/scripts/snowflake/` — ant expands `${basedir}` to the module
  directory, so the load works from any checkout location. The ant targets
  `<unzip>` the parquet archives into that directory first, so no manual
  extraction is needed.
