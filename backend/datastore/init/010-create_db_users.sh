#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

echo "Resetting password for ${POSTGRES_USER}"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    ALTER USER $POSTGRES_USER WITH ENCRYPTED PASSWORD '${POSTGRES_PASSWORD}';
EOSQL

echo "Creating directus db user: ${DIRECTUS_DB_USER} for database ${DIRECTUS_DB_DATABASE}"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE ${DIRECTUS_DB_DATABASE};
    CREATE USER ${DIRECTUS_DB_USER} WITH ENCRYPTED PASSWORD '${DIRECTUS_DB_PASSWORD}';
    ALTER DATABASE ${DIRECTUS_DB_DATABASE} OWNER TO ${DIRECTUS_DB_USER};
    GRANT ALL PRIVILEGES ON DATABASE ${DIRECTUS_DB_DATABASE} TO ${DIRECTUS_DB_USER};
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${DIRECTUS_DB_USER};
    GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO ${DIRECTUS_DB_USER};
EOSQL

echo "DB users setup done.";
