#!/bin/bash

# let the script exit on errors (even within pipes), check for unset vars and disable globbing
# see https://sipb.mit.edu/doc/safe-shell
set -euf -o pipefail


SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

USER=$(python $SCRIPT_DIR/nmsprime_get_env.py user local)
PASSWD=$(python $SCRIPT_DIR/nmsprime_get_env.py password local)
DB=$(python $SCRIPT_DIR/nmsprime_get_env.py db local)
CCC_USER=$(python $SCRIPT_DIR/nmsprime_get_env.py user_ccc local)
CCC_PASSWD=$(python $SCRIPT_DIR/nmsprime_get_env.py password_ccc local)
CCC_DB=$(python $SCRIPT_DIR/nmsprime_get_env.py db_ccc local)
DUMPDIR="/root/db_dumps"
NMSPRIME_DIR="/var/www/nmsprime"

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
	mkdir $DUMPDIR
fi

# get the branch name to add it to dumpfile name
cd $NMSPRIME_DIR
BRANCH=$(git branch | grep "*" | cut -c 3- | tr '/' '__')

TIMESTAMP="`date +%Y-%m-%dT%H-%M-%S`"
PREFIX=$DB
CCC_PREFIX=$CCC_DB
SUFFIX=".sql.bz2"

DUMPFILE="$DUMPDIR"/"$TIMESTAMP"__"$BRANCH$DESC"__"$PREFIX$SUFFIX"
CCC_DUMPFILE="$DUMPDIR"/"$TIMESTAMP"__"$BRANCH$DESC"__"$CCC_PREFIX$SUFFIX"

# set pipefail to catch errors from each piped command
set -o pipefail

echo "Dumping database $DB to $DUMPFILE…"
mysqldump --opt --add-drop-database --user=$USER --password=$PASSWD --databases $DB | bzip2 > $DUMPFILE

echo "Dumping database $CCC_DB to $CCC_DUMPFILE…"
mysqldump --opt --add-drop-database --user=$CCC_USER --password=$CCC_PASSWD --databases $CCC_DB | bzip2 > $CCC_DUMPFILE

echo "Success"

echo
exit 0
