# ==============================================================================
# i2b2-snowflake -- convenience wrapper around the Snowflake key-pair setup and
# data-installation workflow.
#
# Snowflake is a cloud service: there is no local container to build/start.
# `make load` connects to a REMOTE Snowflake account and loads the i2b2 data.
#
# The ACCOUNTADMIN provisioning (snowsight_admin_setup.sql) is a SEPARATE,
# one-time manual task run in Snowsight -- it is intentionally NOT a target here.
#
# Workflow (see README.md):
#   make keys            generate the RSA key pair (once)
#   make pubkey          print the public-key value for snowsight_admin_setup.sql
#     -> run snowsight_admin_setup.sql in Snowsight as ACCOUNTADMIN (separate)
#   make load            load the i2b2 data as the service user
#
# Configure below (or override on the command line, e.g. `make load
# SNOWFLAKE_ACCOUNT=abc12345.us-east-2.aws`). Values must match
# snowsight_admin_setup.sql. No shell `export` is needed -- these are passed to
# the loader directly.
# ==============================================================================

SHELL := /bin/bash

# ---- configuration -----------------------------------------------------------
# Set your account here, or pass `make load SNOWFLAKE_ACCOUNT=...`.
SNOWFLAKE_ACCOUNT     ?= TKNLTGA-I2B2_TEST
I2B2_PRIVATE_KEY_FILE ?= rsa_key.p8
I2B2_PRIVATE_KEY_PWD  ?= "demopass"
I2B2_ROLE             ?= I2B2
I2B2_WAREHOUSE        ?= I2B2_ETL_WH
I2B2_DB               ?= I2B2_DEV
I2B2_USER             ?= I2B2
I2B2_CORE_SERVER_HOST ?= localhost
PUBLIC_KEY            ?= rsa_key.pub

.DEFAULT_GOAL := help

.PHONY: help keys pubkey check load clean-keys

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "} {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

keys: $(I2B2_PRIVATE_KEY_FILE) ## Generate the RSA key pair (encrypted private key + public key)

$(I2B2_PRIVATE_KEY_FILE):
	@echo "Generating encrypted PKCS#8 key pair ($(I2B2_PRIVATE_KEY_FILE), $(PUBLIC_KEY))..."
	openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out $(I2B2_PRIVATE_KEY_FILE) -v2 aes-256-cbc
	openssl rsa -in $(I2B2_PRIVATE_KEY_FILE) -pubout -out $(PUBLIC_KEY)
	@chmod 600 $(I2B2_PRIVATE_KEY_FILE)

pubkey: $(PUBLIC_KEY) ## Print the public-key value to paste into snowsight_admin_setup.sql
	@grep -v -- '-----' $(PUBLIC_KEY) | tr -d '\n'; echo

check: ## Verify required config and the private key are present
	@test -n "$(SNOWFLAKE_ACCOUNT)" \
		|| { echo "Set SNOWFLAKE_ACCOUNT in the Makefile or: make load SNOWFLAKE_ACCOUNT=..." >&2; exit 1; }
	@test -f "$(I2B2_PRIVATE_KEY_FILE)" \
		|| { echo "Private key not found: $(I2B2_PRIVATE_KEY_FILE)" >&2; exit 1; }
	@echo "OK: SNOWFLAKE_ACCOUNT set, private key present ($(I2B2_PRIVATE_KEY_FILE))."

load: check ## Load the i2b2 data into Snowflake (connects as the service user)
	SNOWFLAKE_ACCOUNT="$(SNOWFLAKE_ACCOUNT)" \
	I2B2_PRIVATE_KEY_FILE="$(I2B2_PRIVATE_KEY_FILE)" \
	I2B2_PRIVATE_KEY_PWD="$(I2B2_PRIVATE_KEY_PWD)" \
	I2B2_ROLE="$(I2B2_ROLE)" \
	I2B2_WAREHOUSE="$(I2B2_WAREHOUSE)" \
	I2B2_DB="$(I2B2_DB)" \
	I2B2_USER="$(I2B2_USER)" \
	I2B2_CORE_SERVER_HOST="$(I2B2_CORE_SERVER_HOST)" \
	bash create_snowflake_image.sh

clean-keys: ## Delete the local RSA key pair
	rm -f $(I2B2_PRIVATE_KEY_FILE) $(PUBLIC_KEY)
