#!/bin/bash

# ==============================================================================
# Script Name: data-load.sh
# Description: Initializes the PostgreSQL i2b2 database, loads schema, and 
#              inserts the i2b2 demo data (CRC, HIVE, Metadata, PM, Workdata).
# Usage:       sh data-load.sh
# Expected Output: Configured PostgreSQL database with pre-loaded i2b2 demo data.
# ==============================================================================

# Enforce strict error handling:
# -e: Exit immediately if a command returns a non-zero status.
# -u: Treat unset variables as an error.
set -eu

I2B2_WILDFLY_HOST="${I2B2_WILDFLY_HOST:-i2b2-core-server}"
I2B2_WILDFLY_PORT="${I2B2_WILDFLY_PORT:-8080}"
PG_HOST="${PG_HOST:-172.17.0.1}" #$(docker network inspect i2b2-net -f '{{range .IPAM.Config}}{{.Gateway}}{{end}}')

PG_USER="postgres"
BASE_DIR="/i2b2"
I2B2_DATA_DIR="$BASE_DIR/i2b2-data/edu.harvard.i2b2.data/Release_1-8/NewInstall"

# Input Validation: Ensure base directory exists
if [[ ! -d "$BASE_DIR" ]]; then
    echo "Error: Base directory $BASE_DIR does not exist."
    exit 1
fi

# Secure credentials using defaults that can be overridden by environment variables
export PGPASSWORD="${PGPASSWORD:-demouser}"
DEMO_PASS="${I2B2_DEMO_PASS:-demouser}"

CRCDATA_DIR="$I2B2_DATA_DIR/Crcdata"
HIVEDATA_DIR="$I2B2_DATA_DIR/Hivedata"
PMDATA_DIR="$I2B2_DATA_DIR/Pmdata"
METADATA_DIR="$I2B2_DATA_DIR/Metadata"
WORKDATA_DIR="$I2B2_DATA_DIR/Workdata"

I2B2_USER="i2b2"
I2B2_DEMODATA_USER="i2b2demodata"
I2B2_HIVE_USER="i2b2hive"
I2B2_IMDATA_USER="i2b2imdata"
I2B2_METADATA_USER="i2b2metadata"
I2B2_PM_USER="i2b2pm"
I2B2_WORKDATA_USER="i2b2workdata"

echo "Base Directory: $BASE_DIR"
echo "Creating i2b2 database.."
echo
psql -U "$PG_USER" -f "$BASE_DIR/i2b2-data/docker/i2b2-pgsql/setup/create-db.sql"
echo 
echo "Creating i2b2 schema.."
echo
psql -U "$I2B2_USER" -w -f "$BASE_DIR/i2b2-data/docker/i2b2-pgsql/setup/create-schema.sql"
echo

# Removing the temporary 'trust' rules and replace them with 'scram-sha-256'

echo "Loading CRC Data..."
CELL="i2b2demodata"
cd "$CRCDATA_DIR"
# Safely replace placeholders in db.properties using a single sed invocation
# Pipe delimiter '|' is used to prevent injection issues if variables contain slashes
sed -e "s|localhost|$PG_HOST|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    -e "s|DB_NAME|$CELL|g" \
    "$BASE_DIR/i2b2-data/docker/i2b2-pgsql/setup/db.properties" > db.properties
ant -f data_build.xml create_crcdata_tables_release_1-8
ant -f data_build.xml create_procedures_release_1-8
ant -f data_build.xml db_demodata_load_data

echo "Loading HIVE Data..."
CELL="i2b2hive"
cd "$HIVEDATA_DIR"
sed -e "s|localhost|$PG_HOST|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    -e "s|DB_NAME|$CELL|g" \
    "$BASE_DIR/i2b2-data/docker/i2b2-pgsql/setup/db.properties" > db.properties
ant -f data_build.xml create_hivedata_tables_release_1-8
ant -f data_build.xml db_hivedata_load_data

echo "Loading Metadata..."
CELL="i2b2metadata"
cd "$METADATA_DIR"
sed -e "s|localhost|$PG_HOST|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    -e "s|DB_NAME|$CELL|g" \
    "$BASE_DIR/i2b2-data/docker/i2b2-pgsql/setup/db.properties" > db.properties
ant -f data_build.xml create_metadata_tables_release_1-8
ant -f data_build.xml db_metadata_load_data 
ant -f data_build.xml create_metadata_procedures_release_1-8
# ant -f data_build.xml db_metadata_run_total_count_sqlserver #issue

echo "Loading PM Data..."
CELL="i2b2pm"
cd "$PMDATA_DIR"
sed -e "s|localhost|$PG_HOST|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    -e "s|DB_NAME|$CELL|g" \
    "$BASE_DIR/i2b2-data/docker/i2b2-pgsql/setup/db.properties" > db.properties
ant -f data_build.xml create_pmdata_tables_release_1-8
ant -f data_build.xml create_triggers_release_1-8

echo "Replacing host:port in Pmdata/scripts/demo/pm_access_insert_data.sql.."
sed -i "s|localhost:9090|$I2B2_WILDFLY_HOST:$I2B2_WILDFLY_PORT|g" "$PMDATA_DIR/scripts/demo/pm_access_insert_data.sql"
echo
ant -f data_build.xml db_pmdata_load_data

echo "Loading Workplace Data..."
CELL="i2b2workdata"
cd "$WORKDATA_DIR"
sed -e "s|localhost|$PG_HOST|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    -e "s|DB_NAME|$CELL|g" \
    "$BASE_DIR/i2b2-data/docker/i2b2-pgsql/setup/db.properties" > db.properties
ant -f data_build.xml create_workdata_tables_release_1-8
ant -f data_build.xml db_workdata_load_data

echo "Updating db_lookup tables in i2b2hive.."
psql -U "$I2B2_HIVE_USER" -d i2b2 -w -c "update crc_db_lookup set c_db_fullschema = 'i2b2demodata';"
psql -U "$I2B2_HIVE_USER" -d i2b2 -w -c "update work_db_lookup set c_db_fullschema = 'i2b2workdata';"
psql -U "$I2B2_HIVE_USER" -d i2b2 -w -c "update ont_db_lookup set c_db_fullschema = 'i2b2metadata';"
echo 

echo "Updating i2b2 demo data: Fixing hardcoded PUBLIC schema references in i2b2metadata(c_dimcode)..."
psql -U "$I2B2_METADATA_USER" -d i2b2 -w -c "update i2b2metadata.i2b2 set c_dimcode = REPLACE(c_dimcode, 'PUBLIC.PATIENT_DIMENSION', 'i2b2demodata.patient_dimension') where c_dimcode LIKE '%PUBLIC.PATIENT_DIMENSION%';"

echo "Demodata inserted successfully."

# echo "Cleaning up temporary installation files..."
# rm -rf /i2b2/i2b2-data/edu.harvard.i2b2.data/

# # for act 
# CELL="i2b2demodata"
# cd "$CRCDATA_DIR"
# sed -e "s|localhost|$PG_HOST|g" -e "s|PWD|$DEMO_PASS|g" -e "s|USER_NAME|$CELL|g" -e "s|DB_NAME|$CELL|g" -e "s|db.project=demo|db.project=act|g" "$BASE_DIR/db.properties" > db.properties	
# ant -f data_build.xml db_demodata_load_data

# # for act 
# CELL="i2b2metadata"
# cd "$METADATA_DIR"
# sed -e "s|localhost|$PG_HOST|g" -e "s|PWD|$DEMO_PASS|g" -e "s|USER_NAME|$CELL|g" -e "s|DB_NAME|$CELL|g" -e "s|db.project=demo|db.project=act|g" "$BASE_DIR/db.properties" > db.properties
# ant -f data_build.xml create_metadata_tables_release_1-8
# ant -f data_build.xml db_metadata_load_data 
