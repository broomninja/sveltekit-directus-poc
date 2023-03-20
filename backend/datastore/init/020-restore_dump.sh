#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Perform all actions as $POSTGRES_USER
export PGUSER="$PG_DB_USER"

echo "Restoring database dump for user ${PG_DB_USER} on database ${PG_DB_DATABASE}"

cat /var/lib/postgresql/backup/dump-023-03-07_02_33_24.sql | psql ${PG_DB_DATABASE}