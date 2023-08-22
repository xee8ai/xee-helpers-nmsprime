#!/bin/bash

# let the script exit on errors (even within pipes), check for unset vars and disable globbing
# see https://sipb.mit.edu/doc/safe-shell
set -euf -o pipefail

function usage {
        echo
        echo "Usage: $0 [restore|prepare] dumpfile"
        echo "  prepare: Delete databases and users and set them up again (using credentials from env)"
        echo "  restore: pg_restore the given dumpfile"
        echo
        echo "  dumpfile: path to dumpfile; only needed when restoring"
        echo
}


if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

PSQL="/usr/pgsql-13/bin/psql"

systemctl restart postgresql-13.service

case "$1" in
    prepare)
        read -r -a NMSPRIME_AUTHS <<< $(grep '^DB_DATABASE\|^DB_USERNAME\|^DB_PASSWORD' /etc/nmsprime/env/global.env | sort | cut -d'=' -f2 | xargs)
        read -r -a NMSPRIME_CCC_AUTHS <<< $(grep '^CCC_DB_DATABASE\|^CCC_DB_USERNAME\|^CCC_DB_PASSWORD' /etc/nmsprime/env/ccc.env | sort | cut -d'=' -f2 | xargs)

        echo "NOT REALLY WORKING ATM – TAKE CARE MANUALLY"
        exit 1

        DROPDATABASES="
        nmsprime
        nmsprime_ccc
        grafana
        "
        DROPUSERS="
        nmsprime
        nmsprime_ccc
        grafana
        "

        echo ">>> Revoking connections for users"
        sudo -u postgres $PSQL -c "REVOKE CONNECT ON DATABASE nmsprime FROM public;"
        sudo -u postgres $PSQL -c "REVOKE CONNECT ON DATABASE nmsprime FROM grafana;"
        sudo -u postgres $PSQL -c "REVOKE CONNECT ON DATABASE nmsprime FROM nmsprime;"
        sudo -u postgres $PSQL -c "REVOKE CONNECT ON DATABASE nmsprime_ccc FROM nmsprime_ccc;"

        for DROPDATABASE in $DROPDATABASES; do
            echo ">>> Dropping databases…"
            sudo -u postgres $PSQL -c "DROP DATABASE IF EXISTS $DROPDATABASE;"
        done
        for DROPUSER in $DROPUSERS; do
            echo ">>> Dropping users…"
            sudo -u postgres $PSQL -c "DROP USER IF EXISTS $DROPUSER;"
        done

        for DROPDATABASE in $DROPDATABASES; do
            echo ">>> Dropping databases…"
            sudo -u postgres $PSQL -c "CREATE DATABASE $DROPDATABASE;"
        done

        echo ">>> Creating users and granting rights…"
        sudo -u postgres $PSQL -d nmsprime -c "
            CREATE USER ${NMSPRIME_AUTHS[2]} PASSWORD '${NMSPRIME_AUTHS[1]}';
            GRANT USAGE, CREATE ON SCHEMA ${NMSPRIME_AUTHS[0]} TO ${NMSPRIME_AUTHS[2]};
            GRANT ALL PRIVILEGES ON ALL Tables in schema ${NMSPRIME_AUTHS[0]} TO ${NMSPRIME_AUTHS[2]};
            GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ${NMSPRIME_AUTHS[0]} TO ${NMSPRIME_AUTHS[2]};
            GRANT SELECT ON ALL TABLES IN SCHEMA ${NMSPRIME_AUTHS[0]} TO grafana;
            GRANT USAGE ON SCHEMA ${NMSPRIME_AUTHS[0]} TO grafana;
        "

        sudo -u postgres $PSQL -d nmsprime_ccc -c "
            CREATE USER ${NMSPRIME_CCC_AUTHS[2]} PASSWORD '${NMSPRIME_CCC_AUTHS[1]}';
            GRANT USAGE, CREATE ON SCHEMA ${NMSPRIME_CCC_AUTHS[0]} TO ${NMSPRIME_CCC_AUTHS[2]};
            GRANT ALL PRIVILEGES ON ALL Tables in schema ${NMSPRIME_CCC_AUTHS[0]} TO ${NMSPRIME_CCC_AUTHS[2]};
            GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA ${NMSPRIME_CCC_AUTHS[0]} TO ${NMSPRIME_CCC_AUTHS[2]};
            GRANT SELECT ON ALL TABLES IN SCHEMA ${NMSPRIME_CCC_AUTHS[0]} TO grafana;
        "
        ;;
    restore)
        if [ "$#" -ne 2 ]; then
            usage
            exit 1
        fi

        if [[ "$2" == *.pg.sql.bz2 ]]; then
            CAT_CMD="bzcat $2"
        elif [[ "$2" == *.pg.sql ]]; then
            CAT_CMD="cat $2"
        else
            echo "ERROR: Filename $1 has to end with “.pg.sql” or with “.pg.sql.bz2”"
            exit 1
        fi

        $CAT_CMD | sudo -u postgres $PSQL
        ;;
    *)
        usage
        exit 1
        ;;
esac

