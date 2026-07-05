#!/usr/bin/env bash
# Creates application roles inside the thesisflow database.
# Runs automatically on first container start via docker-entrypoint-initdb.d.
set -euo pipefail

psql -v ON_ERROR_STOP=1 \
     --username "$POSTGRES_USER" \
     --dbname   "$POSTGRES_DB" <<-SQL

    -- Application roles (no superuser, no create-db, no create-role)
    CREATE USER thesisflow_migrator WITH PASSWORD '${THESISFLOW_MIGRATOR_PASSWORD}'
        NOSUPERUSER NOCREATEDB NOCREATEROLE;

    CREATE USER thesisflow_app WITH PASSWORD '${THESISFLOW_APP_PASSWORD}'
        NOSUPERUSER NOCREATEDB NOCREATEROLE;

    CREATE USER thesisflow_readonly WITH PASSWORD '${THESISFLOW_READONLY_PASSWORD}'
        NOSUPERUSER NOCREATEDB NOCREATEROLE;

    -- Allow all three roles to connect to the database
    GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO thesisflow_migrator;
    GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO thesisflow_app;
    GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO thesisflow_readonly;

SQL
