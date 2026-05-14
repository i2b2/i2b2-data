#!/bin/bash

# ==============================================================================
# Script Name: create_pgsql_image.sh
# Description: Prepares the docker environment, starts the PostgreSQL container 
#              via Docker Compose, and triggers the image build process upon success.
# Usage:       sh create_pgsql_image.sh <IMAGE_TAG>
# Arguments:   $1 - The tag to be applied to the newly built PostgreSQL image.
# ==============================================================================

export I2B2_DATA_PGSQL_TAG=$1

echo "Starting postgres docker container.."
# Start the i2b2-pg container (runs data load and initialization setup)
docker compose up i2b2-pg

# Check if the docker compose command finished successfully
if [ $? -eq 0 ]; then 
    echo "completed the scripts, building the docker image now.."
    # Execute the secondary script to commit, build, and push the image
    sh dockerimage.sh
else
    echo "failed to commit the docker image"
    exit 1    
fi