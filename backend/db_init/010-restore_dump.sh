#!/bin/bash

set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$DB_USER"

echo "Restoring database dump for user ${DB_USER} on database ${DB_DATABASE}"

cat /var/lib/postgresql/backup/dump-023-03-07_02_33_24.sql | psql ${DB_DATABASE}