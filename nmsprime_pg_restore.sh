#!/bin/bash

# let the script exit on errors (even within pipes), check for unset vars and disable globbing
# see https://sipb.mit.edu/doc/safe-shell
set -euf -o pipefail

echo

if [ "$#" -ne 1 ]; then
	echo "ERROR:"
	echo "Either no file for import given"
	exit 1
fi

if [[ "$1" == *.pg.sql.bz2 ]]; then
	CAT_CMD="bzcat $1"
elif [[ "$1" == *.pg.sql ]]; then
	CAT_CMD="cat $1"
else
    echo "ERROR: Filename $1 has to end with “.pg.sql” or with “.pg.sql.bz2”"
    exit 1
fi

$CAT_CMD $1 | sudo -u postgres /usr/pgsql-13/bin/psql
