/*********************************************************
*  i2b2 SNOWFLAKE ADMIN SETUP  (run in the Snowflake app)
*
*  Run this ONCE in a Snowsight worksheet as a role that can
*  create roles and users (ACCOUNTADMIN or SECURITYADMIN).
*  It creates the ROLE, WAREHOUSE, DATABASE, the six i2b2
*  SCHEMAS, the functional USER and all the GRANTS the data
*  installer needs.
*
*  This is intentionally SEPARATE from create_snowflake_image.sh:
*  that orchestrator only loads data and runs as the functional
*  user below -- it does NOT need ACCOUNTADMIN.
*
*  The functional user is a SERVICE user that authenticates with
*  KEY-PAIR (RSA) auth -- no password. Generate a key pair first:
*
*     # private key (encrypted; drop -v2/-passout for an unencrypted key)
*     openssl genrsa 2048 | \
*         openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -v2 aes-256-cbc
*     # matching public key
*     openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
*     # value to paste into RSA_PUBLIC_KEY (strips PEM header/footer + newlines)
*     grep -v -- '-----' rsa_key.pub | tr -d '\n'
*
*  >>> PASTE the public key body below before running. If you change
*      any object names, set the matching env vars
*      (I2B2_ROLE / I2B2_WAREHOUSE / I2B2_DB / I2B2_USER) when you run
*      create_snowflake_image.sh, and point it at rsa_key.p8 via
*      I2B2_PRIVATE_KEY_FILE.
*********************************************************/

USE ROLE ACCOUNTADMIN;

-- 1. Role ------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS I2B2;

-- 2. Warehouse -------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS I2B2_ETL_WH
    WAREHOUSE_SIZE      = 'XSMALL'
    AUTO_SUSPEND        = 60
    AUTO_RESUME         = TRUE
    INITIALLY_SUSPENDED = TRUE;
GRANT USAGE, OPERATE ON WAREHOUSE I2B2_ETL_WH TO ROLE I2B2;

-- 3. Database and the six i2b2 schemas -------------------------------------
CREATE DATABASE IF NOT EXISTS I2B2_DEV;
USE DATABASE I2B2_DEV;

CREATE SCHEMA IF NOT EXISTS I2B2METADATA;   -- Metadata cell (ontology)
CREATE SCHEMA IF NOT EXISTS I2B2DATA;       -- CRC / data mart cell
CREATE SCHEMA IF NOT EXISTS I2B2HIVE;       -- Hive cell (db lookups)
CREATE SCHEMA IF NOT EXISTS I2B2IMDATA;     -- Identity management cell
CREATE SCHEMA IF NOT EXISTS I2B2PM;         -- Project management cell
CREATE SCHEMA IF NOT EXISTS I2B2WORKDATA;   -- Workplace cell

-- 4. Grants: full privileges on the database + current and future objects
--    so the installer can create tables, sequences, views, procedures and
--    load data into every schema.
GRANT ALL PRIVILEGES ON DATABASE  I2B2_DEV                 TO ROLE I2B2;
GRANT ALL PRIVILEGES ON ALL SCHEMAS    IN DATABASE I2B2_DEV TO ROLE I2B2;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE I2B2_DEV TO ROLE I2B2;
GRANT ALL PRIVILEGES ON ALL TABLES     IN DATABASE I2B2_DEV TO ROLE I2B2;
GRANT ALL PRIVILEGES ON FUTURE TABLES  IN DATABASE I2B2_DEV TO ROLE I2B2;
GRANT ALL PRIVILEGES ON ALL SEQUENCES    IN DATABASE I2B2_DEV TO ROLE I2B2;
GRANT ALL PRIVILEGES ON FUTURE SEQUENCES IN DATABASE I2B2_DEV TO ROLE I2B2;
GRANT ALL PRIVILEGES ON ALL VIEWS      IN DATABASE I2B2_DEV TO ROLE I2B2;
GRANT ALL PRIVILEGES ON FUTURE VIEWS   IN DATABASE I2B2_DEV TO ROLE I2B2;

-- Stages + file formats: the ACT ontology / concept loaders create an internal
-- stage (PARQUET_STAGE) and a file format (PARQUET_FORMAT), PUT parquet files
-- to the stage and COPY INTO the tables. CREATE STAGE / CREATE FILE FORMAT are
-- part of ALL PRIVILEGES ON SCHEMA above, but grant object access explicitly so
-- the role can also use stages/file formats it did not create.
GRANT CREATE STAGE, CREATE FILE FORMAT ON SCHEMA I2B2METADATA TO ROLE I2B2;
GRANT CREATE STAGE, CREATE FILE FORMAT ON SCHEMA I2B2DATA     TO ROLE I2B2;
GRANT ALL PRIVILEGES ON ALL STAGES         IN DATABASE I2B2_DEV TO ROLE I2B2;
GRANT ALL PRIVILEGES ON FUTURE STAGES      IN DATABASE I2B2_DEV TO ROLE I2B2;
GRANT USAGE          ON ALL FILE FORMATS    IN DATABASE I2B2_DEV TO ROLE I2B2;
GRANT USAGE          ON FUTURE FILE FORMATS IN DATABASE I2B2_DEV TO ROLE I2B2;

-- 5. Functional SERVICE user used by the ant data installer ----------------
--    Key-pair auth only (no password). TYPE = SERVICE users are meant for
--    programmatic access and cannot log in interactively or with a password.
--    >>> PASTE the public key body (base64, no -----BEGIN/END----- lines) <<<
CREATE USER IF NOT EXISTS I2B2
    TYPE              = SERVICE
    RSA_PUBLIC_KEY    = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A...REPLACE_WITH_PUBLIC_KEY_BODY...'
    DEFAULT_ROLE      = I2B2
    DEFAULT_WAREHOUSE = I2B2_ETL_WH
    DEFAULT_NAMESPACE = I2B2_DEV
    COMMENT           = 'i2b2 data installer service account (key-pair auth)';
GRANT ROLE I2B2 TO USER I2B2;

-- To rotate the key later:
--   ALTER USER I2B2 SET RSA_PUBLIC_KEY = '<new public key body>';
