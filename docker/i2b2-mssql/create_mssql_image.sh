#!/bin/bash

# ==============================================================================
# Script Name: create_mssql_image.sh
# Description: Creates, configures, and pushes a Docker image containing 
#              an MSSQL database pre-loaded with i2b2 demo data.
# Usage:       bash create_mssql_image.sh <I2B2_DATA_MSSQL_TAG>
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

#local build or CI build
if [ "${CI:-}" = "true" ]; then
    echo "Running in GitHub Actions.."
else
    echo "Running Locally.."
    echo "This script requires sudo access to install Ant ."
    sudo apt update && sudo apt install -y ant 
    export docker_username="local"
    export docker_reponame="local"
fi

I2B2_DATA_MSSQL_TAG="${1:-local}"
I2B2_WILDFLY_HOST="i2b2-core-server"
I2B2_WILDFLY_PORT="8080"

CORE_SERVER_REPO="$(pwd)/.."
i2b2_data_path="$(pwd)/../.."
configuration_path="$i2b2_data_path/docker/i2b2-mssql/configuration"
dbproperties_path="$i2b2_data_path/docker/i2b2-mssql/configuration/db.properties"


# Helper function to wait for SQL server to be ready
wait_for_mssql() {
    echo "Waiting for MSSQL to initialize..."
    for i in {1..30}; do
        if docker logs i2b2-mssql 2>&1 | grep -q "SQL Server is now ready for client connections"; then
            echo "MSSQL is ready."
            return 0
        fi
        sleep 5
    done
    echo "MSSQL failed to initialize within the timeout period."
    exit 1
}

cd "$i2b2_data_path"

DEMO_PASS="${I2B2_DEMO_PASS:-Demouser123}"
SA_PASSWORD="${MSSQL_SA_PASSWORD:-<YourStrong@Passw0rd>}"
cd "$configuration_path"

echo "Creating Docker network and starting MSSQL container..."
docker network create i2b2-net || true
DOCKER_GATEWAY_IP=$(docker network inspect i2b2-net -f '{{range .IPAM.Config}}{{.Gateway}}{{end}}')

docker run -i -e "ACCEPT_EULA=Y"  -e "SA_PASSWORD=$SA_PASSWORD" -e "TZ=America/New_York" -p 1433:1433 --net i2b2-net --name i2b2-mssql -d mcr.microsoft.com/mssql/server:2019-latest

echo "Waiting for MSSQL to initialize..."
wait_for_mssql
docker ps


echo "Installing prerequisites inside the MSSQL container..."
# 1. Install standard tools PLUS sqlpackage prerequisites (unzip, libunwind8)
#fix the ubuntu package issue - http to https
docker exec --user root i2b2-mssql bash -c "sed -i 's|http://archive.ubuntu.com|https://archive.ubuntu.com|g' /etc/apt/sources.list && sed -i 's|http://security.ubuntu.com|https://security.ubuntu.com|g' /etc/apt/sources.list &&  apt-get update && apt-get install -yq curl apt-transport-https gnupg unzip libunwind8 && curl -sL https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && curl -sL https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2019.list | tee /etc/apt/sources.list.d/mssql-server-2019.list && apt-get update && apt-get install -y mssql-server-fts mssql-tools unixodbc-dev"

# 2. Download sqlpackage, extract it, set symlinks for permanent global access, and clean up
docker exec --user root i2b2-mssql bash -c "curl -sL -o sqlpackage.zip https://aka.ms/sqlpackage-linux && unzip -qq sqlpackage.zip -d /opt/sqlpackage && chmod +x /opt/sqlpackage/sqlpackage && rm sqlpackage.zip && ln -s /opt/sqlpackage/sqlpackage /usr/local/bin/sqlpackage && ln -s /opt/mssql-tools/bin/sqlcmd /usr/local/bin/sqlcmd && ln -s /opt/mssql-tools/bin/bcp /usr/local/bin/bcp && apt-get clean && rm -rf /var/lib/apt/lists/*"

echo "Restarting MSSQL container to apply changes..."
docker restart i2b2-mssql
wait_for_mssql

echo "Verifying Full-Text Search installation..."
docker exec -i -e SQLCMDPASSWORD="$SA_PASSWORD" i2b2-mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -Q  "SELECT FULLTEXTSERVICEPROPERTY('IsFullTextInstalled') AS IsFullTextInstalled;"
sleep 10

docker exec -i -e SQLCMDPASSWORD="$SA_PASSWORD" i2b2-mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -Q 'SELECT name, database_id,create_date FROM sys.databases ;'

echo "Creating databases and users..."
docker exec -i -e SQLCMDPASSWORD="$SA_PASSWORD" i2b2-mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -Q "$(sh $configuration_path/create_dbs.sh)"
sleep 20
docker exec -i -e SQLCMDPASSWORD="$SA_PASSWORD" i2b2-mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -Q "$(sh $configuration_path/create_users.sh)"

docker exec -i -e SQLCMDPASSWORD="$SA_PASSWORD" i2b2-mssql /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -Q 'SELECT name, database_id,create_date FROM sys.databases ;'

/sbin/ip route|awk '/default/ { print $3 }' || true #local network gateway

echo "=================== LOADING DATA INTO CELLS ==================="

# CRC Data
echo "Loading CRC Data..." 
CELL=i2b2demodata
cd "$i2b2_data_path/edu.harvard.i2b2.data/Release_1-8/NewInstall/Crcdata/"
sed -e "s|localhost|$DOCKER_GATEWAY_IP|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    -e "s|DB_NAME|$CELL|g" \
    "$dbproperties_path" > db.properties
ant -f data_build.xml create_crcdata_tables_release_1-8
ant -f data_build.xml create_procedures_release_1-8
ant -f data_build.xml db_demodata_load_data

# HIVE Data
echo "Loading HIVE Data..."
CELL=i2b2hive
cd "$i2b2_data_path/edu.harvard.i2b2.data/Release_1-8/NewInstall/Hivedata"
sed -e "s|localhost|$DOCKER_GATEWAY_IP|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    -e "s|DB_NAME|$CELL|g" \
    "$dbproperties_path" > db.properties
ant -f data_build.xml create_hivedata_tables_release_1-8
ant -f data_build.xml db_hivedata_load_data

# Metadata
echo "Loading Metadata..."
CELL=i2b2metadata
cd "$i2b2_data_path/edu.harvard.i2b2.data/Release_1-8/NewInstall/Metadata"
sed -e "s|localhost|$DOCKER_GATEWAY_IP|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    -e "s|DB_NAME|$CELL|g" \
    "$dbproperties_path" > db.properties
ant -f data_build.xml create_metadata_tables_release_1-8
ant -f data_build.xml db_metadata_load_data 

# IM Data
echo "Loading IM Data..."
CELL=i2b2imdata
cd "$i2b2_data_path/edu.harvard.i2b2.data/Release_1-8/NewInstall/Imdata"
sed -e "s|localhost|$DOCKER_GATEWAY_IP|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    -e "s|DB_NAME|$CELL|g" \
    "$dbproperties_path" > db.properties
ant -f data_build.xml create_imdata_tables_release_1-8
ant -f data_build.xml db_imdata_load_data 

# PM Data
echo "Loading PM Data..."
CELL=i2b2pm
cd "$i2b2_data_path/edu.harvard.i2b2.data/Release_1-8/NewInstall/Pmdata"
sed -e "s|localhost|$DOCKER_GATEWAY_IP|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    -e "s|DB_NAME|$CELL|g" \
    "$dbproperties_path" > db.properties

echo "Replacing host:port in Pmdata/scripts/demo/pm_access_insert_data.sql.."
sed -i "s/localhost:9090/$I2B2_WILDFLY_HOST:$I2B2_WILDFLY_PORT/g" "$i2b2_data_path/edu.harvard.i2b2.data/Release_1-8/NewInstall/Pmdata/scripts/demo/pm_access_insert_data.sql"

ant -f data_build.xml create_pmdata_tables_release_1-8
ant -f data_build.xml create_triggers_release_1-8
ant -f data_build.xml db_pmdata_load_data

# Workplace Data
echo "Loading Workplace Data..."
CELL=i2b2workdata
cd "$i2b2_data_path/edu.harvard.i2b2.data/Release_1-8/NewInstall/Workdata"
sed -e "s|localhost|$DOCKER_GATEWAY_IP|g" \
    -e "s|PWD|$DEMO_PASS|g" \
    -e "s|USER_NAME|$CELL|g" \
    -e "s|DB_NAME|$CELL|g" \
    "$dbproperties_path" > db.properties
ant -f data_build.xml create_workdata_tables_release_1-8
ant -f data_build.xml db_workdata_load_data

echo "=================== DATA LOADING COMPLETE ==================="


sleep 20
df -h

if [ "${CI:-}" = "true" ]; then
    echo "Cleaning up i2b2-data repo to resolve space issues..." #Space Issue in Github CI Pipeline
    rm -rf .git
    rm -rf "$i2b2_data_path/edu.harvard.i2b2.data/"
fi

echo "Completed data load for i2b2-data-mssql."

echo "Committing and pushing Docker image..."
docker commit i2b2-mssql "${docker_username}/${docker_reponame}:i2b2-data-mssql_${I2B2_DATA_MSSQL_TAG}"
docker push "${docker_username}/${docker_reponame}:i2b2-data-mssql_${I2B2_DATA_MSSQL_TAG}"


# #for act 
# CELL=i2b2demodata
# cd "$i2b2_data_path/edu.harvard.i2b2.data/Release_1-8/NewInstall/Crcdata/""
# cat "$dbproperties_path" | sed "s/localhost/$DOCKER_GATEWAY_IP/g" |sed "s/PWD/$DEMO_PASS/g" | sed "s/USER_NAME/$CELL/g"| sed "s/DB_NAME/$CELL/g" > db.properties	
# cat db.properties
# ant -f data_build.xml create_crcdata_tables_release_1-8 #only 1 executes
# # ant -f data_build.xml create_procedures_release_1-8
# ant -f data_build.xml db_demodata_load_data

# CELL=i2b2metadata
# cd "$i2b2_data_path/edu.harvard.i2b2.data/Release_1-8/NewInstall/Metadata"
# cat "$dbproperties_path"  | sed "s/localhost/$DOCKER_GATEWAY_IP/" |sed  "s/PWD/$DEMO_PASS/" | sed "s/USER_NAME/$CELL/"| sed "s/DB_NAME/$CELL/" > db.properties
# cat db.properties
# ant -f data_build.xml create_metadata_tables_release_1-8
# ant -f data_build.xml db_metadata_load_data 
# # ant -f data_build.xml create_metadata_procedures_release_1-8
# # ant -f data_build.xml db_metadata_load_identified_data 



#creating i2b2-mssql-vol image
# docker run --rm --volumes-from i2b2-mssql --name i2b2-mssql-vol -v /tmp/job1:/backup ubuntu tar cvf /backup/backup.tar /var/opt/mssql
# sleep 60
# docker run -d -v /tmp/job1:/backup --name i2b2-mssql-vol-backup ubuntu /bin/sh -c "cd / && tar xvf /backup/backup.tar"
# ls 
# sleep 100
# docker commit i2b2-mssql-vol-backup local/i2b2-mssql-vol


# docker tag local/i2b2-mssql-vol host_name/new_repo:i2b2-mssql-vol-$I2B2_DATA_MSSQL_TAG
# docker push host_name/new_repo:i2b2-mssql-vol-$I2B2_DATA_MSSQL_TAG
# docker rm -f i2b2-mssql i2b2-mssql-vol-backup