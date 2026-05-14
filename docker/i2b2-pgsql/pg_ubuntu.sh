#!/bin/bash

# ==============================================================================
# Script Name: pg_ubuntu.sh
# Description: Installs and configures PostgreSQL on an Ubuntu container.
# ==============================================================================
#!/bin/bash
# set -eu

export DEBIAN_FRONTEND=noninteractive

# FIX: handle Ubuntu 24.04 (.sources + .list)
find /etc/apt -type f \( -name "*.list" -o -name "*.sources" \) -exec \
  sed -i 's|http://archive.ubuntu.com/ubuntu|http://azure.archive.ubuntu.com/ubuntu|g' {} \;

find /etc/apt -type f \( -name "*.list" -o -name "*.sources" \) -exec \
  sed -i 's|http://security.ubuntu.com/ubuntu|http://azure.archive.ubuntu.com/ubuntu|g' {} \;

# Network tuning (prevents "Waiting for headers")
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
echo 'Acquire::Retries "3";' > /etc/apt/apt.conf.d/80-retries
echo 'Acquire::http::Timeout "30";' > /etc/apt/apt.conf.d/99timeout


apt-get update
apt-get install -y postgresql postgresql-contrib ant

# Clean up apt cache to reduce image size
rm -rf /var/lib/apt/lists/*

# /etc/init.d/postgresql status
/etc/init.d/postgresql start

echo "started postgresql service on ubuntu container"

date
#updating postgresql configuration
echo "timezone = 'America/New_York'" >> /etc/postgresql/16/main/postgresql.conf

sed -i "0,/#listen_addresses = 'localhost'/s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/16/main/postgresql.conf

sed -i 's/local   all             postgres                                peer/local   all             postgres                                trust/' /etc/postgresql/16/main/pg_hba.conf

sed -i 's/local   all             all                                     peer/local   all             all                                     md5/' /etc/postgresql/16/main/pg_hba.conf

sed -i 's#host    all             all             127.0.0.1/32            scram-sha-256#host    all             all             0.0.0.0/0            scram-sha-256#g' /etc/postgresql/16/main/pg_hba.conf

user_name=$(whoami)
/etc/init.d/postgresql restart

echo "Waiting for PostgreSQL to be ready..."

until pg_isready -U postgres; do
    sleep 2
done

echo "PostgreSQL is ready"

date 
echo "executing data-load.sh"
echo "==========================================="
bash /i2b2/i2b2-data/docker/i2b2-pgsql/data-load.sh
