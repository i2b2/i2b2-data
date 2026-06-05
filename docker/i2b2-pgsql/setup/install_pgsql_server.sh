#!/bin/bash

# ==============================================================================
# Script Name: pg_ubuntu.sh
# Description: Installs and configures PostgreSQL on an Ubuntu container.
# ==============================================================================
# set -eu

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y postgresql postgresql-contrib ant

# Clean up apt cache to reduce image size
rm -rf /var/lib/apt/lists/*

/etc/init.d/postgresql start

echo "started postgresql service on ubuntu container"

PG_CONF="/etc/postgresql/16/main/postgresql.conf"
PG_HBA="/etc/postgresql/16/main/pg_hba.conf"

date
#updating postgresql configuration
echo "timezone = 'America/New_York'" >> $PG_CONF

sed -i "0,/#listen_addresses = 'localhost'/s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $PG_CONF

sed -i 's/local   all             postgres                                peer/local   all             postgres                                trust/' $PG_HBA

sed -i 's/local   all             all                                     peer/local   all             all                                     md5/' $PG_HBA

sed -i 's#host    all             all             127.0.0.1/32            scram-sha-256#host    all             all             0.0.0.0/0            scram-sha-256#g' $PG_HBA


/etc/init.d/postgresql restart

echo "Waiting for PostgreSQL to be ready..."

until pg_isready -U postgres; do
    sleep 2
done

echo "PostgreSQL is ready"

date 
echo "executing data-load.sh"
echo "==========================================="
source /i2b2/i2b2-data/docker/i2b2-pgsql/setup/data-load.sh

echo "==========================================="
echo "SCRAM-SHA-256"
sed -i "s/^local.*all.*peer/local all all scram-sha-256/" $PG_HBA
sed -i "s/^host.*all.*127.0.0.1.*ident/host all all 127.0.0.1\/32 scram-sha-256/" $PG_HBA