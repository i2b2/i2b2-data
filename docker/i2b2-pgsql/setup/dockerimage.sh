#!/bin/bash

# ==============================================================================
# Script Name: dockerimage.sh
# Description: Commits the running Postgres container to an image and pushes it.
# ==============================================================================

set -eu

docker commit i2b2-pg "${docker_username}/${docker_reponame}:i2b2-data-pgsql-container-commit-${I2B2_DATA_PGSQL_TAG}"
echo "Completed committing the docker image."

sed -i "s#image_tag#${docker_username}/${docker_reponame}:i2b2-data-pgsql-container-commit-${I2B2_DATA_PGSQL_TAG}#g" Dockerfile

docker images 
docker build -t "${docker_username}/${docker_reponame}:i2b2-data-pgsql_${I2B2_DATA_PGSQL_TAG}" .
docker push "${docker_username}/${docker_reponame}:i2b2-data-pgsql_${I2B2_DATA_PGSQL_TAG}"

# Revert the Dockerfile modification
git restore Dockerfile || sed -i "s#${docker_username}/${docker_reponame}:i2b2-data-pgsql-container-commit-${I2B2_DATA_PGSQL_TAG}#image_tag#g" Dockerfile

echo "Docker image built successfully."
