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
| `Makefile` | Convenience wrapper around the whole workflow (`make keys`, `make pubkey`, `make load`). |

## Two-step split

1. **Admin (once, in Snowsight):** an ACCOUNTADMIN runs `snowsight_admin_setup.sql`.
2. **Data load (repeatable, automated):** anyone with the service user's private key runs `create_snowflake_image.sh`.

## Authentication

The functional user is a Snowflake **`TYPE = SERVICE`** account using **key-pair (RSA) auth** — no password. Generate a key pair before running the admin script:

```bash
make keys      # generate the encrypted RSA key pair (rsa_key.p8, rsa_key.pub)
make pubkey    # print the value to paste into RSA_PUBLIC_KEY in snowsight_admin_setup.sql
```

Equivalent manual commands:

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

**Step 2 — load data:** configuration lives in the `Makefile` — set
`SNOWFLAKE_ACCOUNT` there (the rest default to values matching
`snowsight_admin_setup.sql`: `I2B2_PRIVATE_KEY_FILE=rsa_key.p8`, `I2B2_ROLE=I2B2`,
`I2B2_WAREHOUSE=I2B2_ETL_WH`, `I2B2_DB=I2B2_DEV`, `I2B2_USER=I2B2`,
`I2B2_PRIVATE_KEY_PWD=`), then:

```bash
make load
```

Or override any value on the command line without editing the file:

```bash
make load SNOWFLAKE_ACCOUNT=I2B2_TEST I2B2_PRIVATE_KEY_PWD=secret
```

`make load` runs `create_snowflake_image.sh`; it first checks that
`SNOWFLAKE_ACCOUNT` is set and the private key exists, then passes the config to
the loader directly — no shell `export` needed. Run `make help` to list all
targets. The data load connects as the service user via key-pair auth and never
needs ACCOUNTADMIN.

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
