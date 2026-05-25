#!/bin/bash

# ==============================================================================
# Script Name: create_pgsql_image.sh
# Description: Prepares the docker environment, starts the PostgreSQL container 
#              via Docker Compose, and triggers the image build process upon success.
# Usage:       bash create_pgsql_image.sh <IMAGE_TAG>
# Arguments:   $1 - The tag to be applied to the newly built PostgreSQL image.
# ==============================================================================

if [ "$CI" = "true" ]; then
    echo "Running in GitHub Actions.."
else
    echo "Running Locally.."
    echo "This script requires sudo access to install Ant ."
    sudo apt update && sudo apt install -y ant 
    export docker_username="local"
    export docker_reponame="local"
fi 

export I2B2_DATA_PGSQL_TAG="${1:-local}"
echo "Starting postgres docker container.."
# Start the i2b2-pg container (runs data load and initialization setup)
cd setup
docker compose up i2b2-pg

# Check if the docker compose command finished successfully
if [ $? -eq 0 ]; then 
    echo "completed the scripts, building the docker image now.."
    # Execute the secondary script to commit, build, and push the image
    bash dockerimage.sh
else
    echo "failed to commit the docker image"
    exit 1    
fi