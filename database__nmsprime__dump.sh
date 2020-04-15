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

CACTI_USER=$(python $SCRIPT_DIR/nmsprime_get_env.py user_cacti local)
CACTI_PASSWD=$(python $SCRIPT_DIR/nmsprime_get_env.py password_cacti local)
CACTI_DB=$(python $SCRIPT_DIR/nmsprime_get_env.py db_cacti local)

ICINGA2_USER=$(python $SCRIPT_DIR/nmsprime_get_env.py user_icinga2 local)
ICINGA2_PASSWD=$(python $SCRIPT_DIR/nmsprime_get_env.py password_icinga2 local)
ICINGA2_DB=$(python $SCRIPT_DIR/nmsprime_get_env.py db_icinga2 local)

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
if ! test -e .git; then
	BRANCH="default"
else
	BRANCH=$(git branch | grep "*" | cut -c 3- | tr '/' '__')
fi

TIMESTAMP="`date +%Y-%m-%dT%H-%M-%S`"
PREFIX=$DB
CCC_PREFIX=$CCC_DB
CACTI_PREFIX=$CACTI_DB
ICINGA2_PREFIX=$ICINGA2_DB
SUFFIX=".sql.bz2"

DUMPFILE="$DUMPDIR"/"$TIMESTAMP"__"$BRANCH$DESC"__"$PREFIX$SUFFIX"
CCC_DUMPFILE="$DUMPDIR"/"$TIMESTAMP"__"$BRANCH$DESC"__"$CCC_PREFIX$SUFFIX"
CACTI_DUMPFILE="$DUMPDIR"/"$TIMESTAMP"__"$BRANCH$DESC"__"$CACTI_PREFIX$SUFFIX"
ICINGA2_DUMPFILE="$DUMPDIR"/"$TIMESTAMP"__"$BRANCH$DESC"__"$ICINGA2_PREFIX$SUFFIX"

# set pipefail to catch errors from each piped command
set -o pipefail

echo "Dumping database $DB to $DUMPFILE…"
mysqldump --opt --add-drop-database --user=$USER --password=$PASSWD --databases $DB | bzip2 > $DUMPFILE

echo "Dumping database $CCC_DB to $CCC_DUMPFILE…"
mysqldump --opt --add-drop-database --user=$CCC_USER --password=$CCC_PASSWD --databases $CCC_DB | bzip2 > $CCC_DUMPFILE

echo "Dumping database $CACTI_DB to $CACTI_DUMPFILE…"
mysqldump --opt --add-drop-database --user=$CACTI_USER --password=$CACTI_PASSWD --databases $CACTI_DB | bzip2 > $CACTI_DUMPFILE

# very huge (and slow)
# echo "Dumping database $ICINGA2_DB to $ICINGA2_DUMPFILE…"
# mysqldump --opt --add-drop-database --user=$ICINGA2_USER --password=$ICINGA2_PASSWD --databases $ICINGA2_DB | bzip2 > $ICINGA2_DUMPFILE

echo "Success"

echo
exit 0
