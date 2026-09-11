#!/bin/bash

# ==============================================================================
# Script Name: create_snowflake_image.sh
# Description: Loads the i2b2 demo/ACT data into Snowflake using the ant data
#              installer, connecting as the functional i2b2 user.
#
#              PREREQUISITE: the ACCOUNTADMIN-level objects (role, warehouse,
#              database, schemas, user, grants) must already exist. Create them
#              once by running `snowsight_admin_setup.sql` in a Snowsight
#              worksheet as ACCOUNTADMIN. This script deliberately does NOT need
#              ACCOUNTADMIN -- it only creates tables and loads data.
#
#              NOTE: Snowflake is a cloud service, so -- unlike the Oracle,
#              MSSQL and PostgreSQL images -- there is no local database
#              container to start or commit. This script connects to a REMOTE
#              Snowflake account. The data lives in Snowflake, not in a docker
#              image.
#
# Usage:       bash create_snowflake_image.sh
#
# Authentication: the functional user is a SERVICE user that authenticates with
# key-pair (RSA) auth -- no password. Point I2B2_PRIVATE_KEY_FILE at the PKCS#8
# private key (rsa_key.p8) whose public key was registered by
# snowsight_admin_setup.sql.
#
# Required environment variables:
#   SNOWFLAKE_ACCOUNT       account identifier, e.g. abc12345.us-east-2.aws
#   I2B2_PRIVATE_KEY_FILE   path to the service user's PKCS#8 private key (rsa_key.p8)
#
# Optional (defaults shown) -- must match snowsight_admin_setup.sql:
#   I2B2_ROLE=I2B2
#   I2B2_WAREHOUSE=I2B2_ETL_WH
#   I2B2_DB=I2B2_DEV
#   I2B2_USER=I2B2
#   I2B2_PRIVATE_KEY_PWD=            (passphrase, only if rsa_key.p8 is encrypted)
#   I2B2_CORE_SERVER_HOST=i2b2-core-server   (used in pm_access cell URLs)
# ==============================================================================

set -euo pipefail

# ---- ant bootstrap -----------------------------------------------------------
# Use the Apache Ant bundled in the repo -- no system install (no sudo/apt/brew)
# is needed, only a JDK, which the ant scripts locate via JAVA_HOME or `java` on
# PATH. Set ANT_HOME/PATH so the plain `ant ...` calls below resolve to it.
script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
ANT_HOME="$repo_root/edu.harvard.i2b2.data/Release_1-8/apache-ant"
[ -x "$ANT_HOME/bin/ant" ] || { echo "Bundled ant not found at $ANT_HOME/bin/ant" >&2; exit 1; }
export ANT_HOME
export PATH="$ANT_HOME/bin:$PATH"

# ---- configuration -----------------------------------------------------------
: "${SNOWFLAKE_ACCOUNT:?Set SNOWFLAKE_ACCOUNT (e.g. abc12345.us-east-2.aws)}"
: "${I2B2_PRIVATE_KEY_FILE:?Set I2B2_PRIVATE_KEY_FILE (path to the service user rsa_key.p8)}"

# Resolve the key to an absolute path: db.properties is read by ant *after* it
# cd's into each module dir, so a relative path would not be found there.
case "$I2B2_PRIVATE_KEY_FILE" in
    /*) : ;;
    *)  I2B2_PRIVATE_KEY_FILE="$(pwd)/$I2B2_PRIVATE_KEY_FILE" ;;
esac
[ -f "$I2B2_PRIVATE_KEY_FILE" ] || { echo "Private key not found: $I2B2_PRIVATE_KEY_FILE" >&2; exit 1; }

I2B2_ROLE="${I2B2_ROLE:-I2B2}"
I2B2_WAREHOUSE="${I2B2_WAREHOUSE:-I2B2_ETL_WH}"
I2B2_DB="${I2B2_DB:-I2B2_DEV}"
I2B2_USER="${I2B2_USER:-I2B2}"
I2B2_CORE_SERVER_HOST="${I2B2_CORE_SERVER_HOST:-i2b2-core-server}"

i2b2_data_path="$repo_root"
newinstall="$i2b2_data_path/edu.harvard.i2b2.data/Release_1-8/NewInstall"

echo "NOTE: this script assumes snowsight_admin_setup.sql has already been run"
echo "      (as ACCOUNTADMIN) to create role '$I2B2_ROLE', warehouse"
echo "      '$I2B2_WAREHOUSE', database '$I2B2_DB', its schemas and the"
echo "      service user '$I2B2_USER' (key-pair auth). It connects as that"
echo "      service user only."

# ---- helper: write key-pair db.properties for a cell and cd into its module --
# args: <module-dir> <schema>
prepare_cell() {
    local module="$1" schema="$2"
    cd "$newinstall/$module"

    local url="jdbc:snowflake://${SNOWFLAKE_ACCOUNT}.snowflakecomputing.com/?db=${I2B2_DB}&schema=${schema}&warehouse=${I2B2_WAREHOUSE}&role=${I2B2_ROLE}&authenticator=SNOWFLAKE_JWT&private_key_file=${I2B2_PRIVATE_KEY_FILE}"
    if [ -n "${I2B2_PRIVATE_KEY_PWD:-}" ]; then
        url="${url}&private_key_file_pwd=${I2B2_PRIVATE_KEY_PWD}"
    fi
    url="${url}&CLIENT_RESULT_COLUMN_CASE_INSENSITIVE=true&JDBC_QUERY_RESULT_FORMAT=JSON"

    cat > db.properties <<EOF
db.type=snowflake
db.username=${I2B2_USER}
db.password=
db.driver=net.snowflake.client.jdbc.SnowflakeDriver
db.url=${url}
db.project=act
EOF
    # Don't cat db.properties -- the URL may contain the private-key passphrase.
    echo "  -> $module: schema=$schema (key-pair auth as $I2B2_USER)"
}

echo "=================== LOADING DATA INTO CELLS ==================="

# ---- CRC / data mart (I2B2DATA) ----------------------------------------------
echo "Loading CRC Data..."
prepare_cell "Crcdata" "I2B2DATA"
ant -f data_build.xml create_crcdata_tables_release_1-8
ant -f data_build.xml db_demodata_load_data

# ---- Hive (I2B2HIVE) ---------------------------------------------------------
echo "Loading HIVE Data..."
prepare_cell "Hivedata" "I2B2HIVE"
ant -f data_build.xml create_hivedata_tables_release_1-8
ant -f data_build.xml db_hivedata_load_data

# ---- IM (I2B2IMDATA) ---------------------------------------------------------
echo "Loading IM Data..."
prepare_cell "Imdata" "I2B2IMDATA"
ant -f data_build.xml create_imdata_tables_release_1-8
# ant -f data_build.xml db_imdata_load_data

# ---- Metadata / ontology (I2B2METADATA) --------------------------------------
echo "Loading Metadata..."
prepare_cell "Metadata" "I2B2METADATA"
ant -f data_build.xml create_metadata_tables_release_1-8
ant -f data_build.xml db_metadata_load_data
# ant -f data_build.xml db_metadata_run_total_count_snowflake   # optional totalnum counts

# ---- PM (I2B2PM) -------------------------------------------------------------
echo "Loading PM Data..."
prepare_cell "Pmdata" "I2B2PM"
echo "Pointing pm_access cell URLs at the i2b2 core server..."
sed -i.bak "s|http://localhost/|http://$I2B2_CORE_SERVER_HOST/|g" \
    "$newinstall/Pmdata/scripts/act/pm_access_insert_data.sql"
rm -f "$newinstall/Pmdata/scripts/act/pm_access_insert_data.sql.bak"
ant -f data_build.xml create_pmdata_tables_release_1-8
ant -f data_build.xml db_pmdata_load_data

# ---- Workplace (I2B2WORKDATA) ------------------------------------------------
echo "Loading Workplace Data..."
prepare_cell "Workdata" "I2B2WORKDATA"
ant -f data_build.xml create_workdata_tables_release_1-8
ant -f data_build.xml db_workdata_load_data

echo "=================== DATA LOADING COMPLETE ==================="
echo "i2b2 data has been installed into Snowflake database '$I2B2_DB'"
echo "(schemas: I2B2METADATA, I2B2DATA, I2B2HIVE, I2B2IMDATA, I2B2PM, I2B2WORKDATA)."
