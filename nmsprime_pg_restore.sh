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
    $PSQLCON nmsprime -c "DROP SCHEMA NMSPRIME CASCADE"
    $CAT_CMD | $PSQLCON nmsprime
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
