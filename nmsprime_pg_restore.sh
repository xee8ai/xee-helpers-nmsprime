#!/bin/bash

# let the script exit on errors (even within pipes), check for unset vars and disable globbing
# see https://sipb.mit.edu/doc/safe-shell
set -euf -o pipefail

function usage {
        echo
        echo "Usage: $0 dumpfile"
        echo
        echo "  dumpfile: path to dumpfile; only needed when restoring"
        echo
}


if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

PSQL="/usr/bin/psql"
PSQLCON="sudo -u postgres $PSQL"

# systemctl restart postgresql-16.service

if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

if [[ ! -f "$1" ]]; then
    echo "$1 does not exist or is not a file. Exiting…"
    echo
    exit 1
fi

if [[ "$1" == *.pg.sql.bz2 ]]; then
    CAT_CMD="bzcat $1"
elif [[ "$1" == *.pg.sql ]]; then
    CAT_CMD="cat $1"
elif [[ "$1" == *.psql ]]; then
    CAT_CMD="cat $1"
else
    echo "ERROR: Filename $1 has to end with “.psql” or with “.pg.sql” or with “.pg.sql.bz2”"
    echo
    exit 1
fi

if [[ "$1" == *__nmsprime.p* ]]; then
    # $PSQLCON nmsprime -c "DROP SCHEMA NMSPRIME CASCADE"
    # $CAT_CMD | $PSQLCON nmsprime

    DB_NAME="nmsprime"
    echo "--- Starting TimescaleDB-aware restore for $DB_NAME ---"

    # 1. Force disconnect active sessions (Max 5 attempts)
    RETRY_COUNT=0
    while [ $RETRY_COUNT -lt 5 ]; do
        SESSION_COUNT=$($PSQLCON postgres -tAc "SELECT count(*) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();")

        if [ "$SESSION_COUNT" -eq "0" ]; then
            echo "No active sessions. Proceeding..."
            break
        fi

        echo "Attempt $((RETRY_COUNT+1)): Terminating $SESSION_COUNT active sessions..."
        $PSQLCON postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();" > /dev/null

        sleep 1
        RETRY_COUNT=$((RETRY_COUNT+1))
    done

    # 2. Perform the Restore
    # We pipe to 'postgres' because the dump contains DROP/CREATE DATABASE
    echo "Restoring data from $1..."
    $CAT_CMD | $PSQLCON postgres --set ON_ERROR_STOP=on

        # 3. Resolve TimescaleDB Version Mismatch
        echo "Syncing TimescaleDB extension versions..."
        # We run this twice: once to update the extension,
        # and once to ensure the catalog scripts are fully applied to the new schema.
        $PSQLCON $DB_NAME -c "ALTER EXTENSION timescaledb UPDATE;"
        $PSQLCON $DB_NAME -c "ALTER EXTENSION timescaledb UPDATE;"

    # 4. Finalize Restore and Re-enable Background Workers
    echo "Finalizing restore and re-enabling workers..."
    if ! $PSQLCON $DB_NAME -c "SELECT timescaledb_post_restore();" 2>/dev/null; then
        echo "Warning: post_restore() failed. Applying manual catalog fix (checking key/name)..."
        # Try 'key' (new versions) and 'name' (old versions)
        $PSQLCON $DB_NAME -c "UPDATE _timescaledb_catalog.metadata SET value = 'false' WHERE key = 'restoring';" 2>/dev/null || \
            $PSQLCON $DB_NAME -c "UPDATE _timescaledb_catalog.metadata SET value = 'false' WHERE name = 'restoring';"
    fi

    echo "Restore of $DB_NAME complete."

elif [[ "$1" == *__nmsprime_ccc.p* ]]; then
    $PSQLCON -c "DROP DATABASE nmsprime_ccc;"
    $PSQLCON -c "CREATE DATABASE nmsprime_ccc;"
    $CAT_CMD | $PSQLCON nmsprime_ccc
else
    echo "ERROR: Filename $1 does not match a known schema."
    echo
    exit 1
fi

$PSQLCON -c "
    SET search_path TO nmsprime,nmsprime_ccc,public;
"
