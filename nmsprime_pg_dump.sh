#!/bin/bash

# exit on first error
set -euf -o pipefail

DUMPCMD="sudo -u postgres /usr/pgsql-13/bin/pg_dump"

DUMPDIR="/root/db_dumps/manually"
NMSPRIME_DIR="/var/www/nmsprime"

DB="nmsprime"
CCC_DB="nmsprime_ccc"

echo

# check if a description is given
# this is expected to be a string containing no spaces
if [ "$#" -eq 1 ]; then
	if [[ $1 == "-h" || $1 == "--help" ]]; then
		echo "Usage: $0 [description]"
	echo
		echo "       optional description is expected to be a string without spaces and will be added to filename"
		echo
		exit 0
	else
		DESC="__"$1
	fi
else
	DESC=""
fi

# warn if more than one argument is given (e.g. a description containing spaces
if [ "$#" -gt 1 ]; then
	echo "ERROR:"
	echo "$0 accepts up to one argument, $# given"
	exit 1
fi

if ! test -e $DUMPDIR; then
	mkdir -p $DUMPDIR
fi

# get the branch name to add it to dumpfile name
cd $NMSPRIME_DIR
if ! test -e .git; then
	BRANCH="default"
else
	BRANCH=$(git branch | grep "*" | cut -c 3- | tr '/' '__')
fi

TIMESTAMP="`date +%Y-%m-%dT%H-%M-%S`"
PREFIX=$DB
CCC_PREFIX=$CCC_DB

SUFFIX=".pg.sql.bz2"

DUMPFILE="$DUMPDIR"/"$TIMESTAMP"__"$BRANCH$DESC"__"$PREFIX$SUFFIX"
CCC_DUMPFILE="$DUMPDIR"/"$TIMESTAMP"__"$BRANCH$DESC"__"$CCC_PREFIX$SUFFIX"

# hint: We are doing plain dumps to be able to read and even edit them later on
# for compression we use bzip2 (so we can use bzcat and bzless to work with compressed files)
# caveat: bzip2 is really slow – but works for our devel databases
# One can simply extract the file (using bunzip) and restore the non-compressed file using nmsprime_pg_restore.sh as well)

echo "Dumping database $DB to $DUMPFILE…"
$DUMPCMD nmsprime -n nmsprime --clean --create --if-exists | bzip2 > $DUMPFILE

echo "Dumping database $CCC_DB to $CCC_DUMPFILE…"
$DUMPCMD nmsprime_ccc -n nmsprime_ccc --clean --create --if-exists | bzip2 > $CCC_DUMPFILE


exit 0
