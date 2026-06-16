
#!/bin/bash

# ==============================================================================
# Script Name: create_oracle_image.sh
# Description: Creates, configures, and pushes a Docker image containing 
#              an Oracle database pre-loaded with i2b2 demo data.
# Usage:       bash create_oracle_image.sh <I2B2_DATA_ORACLE_TAG>
# Expected Output: A committed Docker image for Oracle with i2b2 data loaded.
# ==============================================================================

# Enforce strict error handling:
# -e: Exit immediately if a command returns a non-zero status.
set -e

#local build or CI build
if [ "$CI" = "true" ]; then
    echo "Running in GitHub Actions.."
else
    echo "Running Locally.."
    echo "This script requires sudo access to install Ant ."
    sudo apt update && sudo apt install -y ant 
    export docker_username="local"
    export docker_reponame="local"
fi

I2B2_DATA_ORACLE_TAG="${1:-local}"
I2B2_CORE_SERVER_HOST="i2b2-core-server"
I2B2_CORE_SERVER_PORT="8080"
I2B2_DATA_PATH=$(pwd)/../..

# Secure credentials using defaults that can be overridden by environment variables
ORACLE_PWD="${ORACLE_PWD:-MyStrongPass123}"
DEMO_PASS="${I2B2_DEMO_PASS:-demouser}"

echo "Creating Docker network i2b2-net..."
docker network create i2b2-net || true

echo "Starting Oracle container..."
docker run -d \
  --name oracle23 \
  -p 1521:1521 \
  -e ORACLE_PWD="$ORACLE_PWD" \
  -v "$I2B2_DATA_PATH:/i2b2" \
  --network i2b2-net \
  container-registry.oracle.com/database/free:latest

echo "Waiting for Oracle to be ready..."
sleep 60

echo "Copying SQL scripts and creating users..."
docker cp create_users.sql oracle23:/

# Securely pass the password into sqlplus via an environment variable inside the single-quoted bash execution
# This protects the password from appearing in the host's or container's process list.
docker exec -e ORACLE_PWD="$ORACLE_PWD" oracle23 bash -c 'sqlplus -s "sys/${ORACLE_PWD}@FREEPDB1" as sysdba @/create_users.sql'

docker_network_gateway_ip=$(docker network inspect i2b2-net -f '{{range .IPAM.Config}}{{.Gateway}}{{end}}')

cd "$I2B2_DATA_PATH"

echo "Loading CRC Data..."
CELL=i2b2demodata
cd "$I2B2_DATA_PATH/edu.harvard.i2b2.data/Release_1-8/NewInstall/Crcdata/"
sed -e "s|localhost|$docker_network_gateway_ip|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    "$I2B2_DATA_PATH/docker/i2b2-oracle/db.properties" > db.properties
cat db.properties

ant -f data_build.xml create_crcdata_tables_release_1-8
ant -f data_build.xml create_procedures_release_1-8
ant -f data_build.xml db_demodata_load_data

echo "Loading HIVE Data..."
CELL=i2b2hive
cd "$I2B2_DATA_PATH/edu.harvard.i2b2.data/Release_1-8/NewInstall/Hivedata"
sed -e "s|localhost|$docker_network_gateway_ip|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    "$I2B2_DATA_PATH/docker/i2b2-oracle/db.properties" > db.properties
ant -f data_build.xml create_hivedata_tables_release_1-8
ant -f data_build.xml db_hivedata_load_data

echo "Loading IM Data..."
CELL=i2b2imdata
cd "$I2B2_DATA_PATH/edu.harvard.i2b2.data/Release_1-8/NewInstall/Imdata"
sed -e "s|localhost|$docker_network_gateway_ip|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    "$I2B2_DATA_PATH/docker/i2b2-oracle/db.properties" > db.properties
cat db.properties
ant -f data_build.xml create_imdata_tables_release_1-8
ant -f data_build.xml db_imdata_load_data 

echo "Loading Metadata..."
CELL=i2b2metadata
cd "$I2B2_DATA_PATH/edu.harvard.i2b2.data/Release_1-8/NewInstall/Metadata"
sed -e "s|localhost|$docker_network_gateway_ip|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    "$I2B2_DATA_PATH/docker/i2b2-oracle/db.properties" > db.properties
cat db.properties
ant -f data_build.xml create_metadata_tables_release_1-8
ant -f data_build.xml db_metadata_load_data 
#ant -f data_build.xml create_metadata_procedures_release_1-8 #not mentioned in installation document
# ant -f data_build.xml db_metadata_load_identified_data #phi data already executing in db_metadata_load_data
# ant -f data_build.xml db_metadata_run_total_count_sqlserver #issue

echo "Loading PM Data..."
CELL=i2b2pm
cd "$I2B2_DATA_PATH/edu.harvard.i2b2.data/Release_1-8/NewInstall/Pmdata"
sed -e "s|localhost|$docker_network_gateway_ip|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    "$I2B2_DATA_PATH/docker/i2b2-oracle/db.properties" > db.properties

echo "Replacing host:port in Pmdata/scripts/demo/pm_access_insert_data.sql.."
sed -i "s|localhost:9090|$I2B2_CORE_SERVER_HOST:$I2B2_CORE_SERVER_PORT|g" "$I2B2_DATA_PATH/edu.harvard.i2b2.data/Release_1-8/NewInstall/Pmdata/scripts/demo/pm_access_insert_data.sql"

ant -f data_build.xml create_pmdata_tables_release_1-8
ant -f data_build.xml create_triggers_release_1-8
ant -f data_build.xml db_pmdata_load_data

echo "Loading Workplace Data..."
CELL=i2b2workdata
cd "$I2B2_DATA_PATH/edu.harvard.i2b2.data/Release_1-8/NewInstall/Workdata"
sed -e "s|localhost|$docker_network_gateway_ip|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    "$I2B2_DATA_PATH/docker/i2b2-oracle/db.properties" > db.properties
ant -f data_build.xml create_workdata_tables_release_1-8
ant -f data_build.xml db_workdata_load_data

if [ "$CI" = "true" ]; then
    echo "Cleaning up i2b2-data repo to resolve space issues..." #Space Issue in Github CI Pipeline
    rm -rf .git
    rm -rf "$I2B2_DATA_PATH/edu.harvard.i2b2.data/"
fi

echo "Committing Docker image..."
docker commit oracle23 "${docker_username}/${docker_reponame}:i2b2-data-oracle_${I2B2_DATA_ORACLE_TAG}"
docker push "${docker_username}/${docker_reponame}:i2b2-data-oracle_${I2B2_DATA_ORACLE_TAG}"