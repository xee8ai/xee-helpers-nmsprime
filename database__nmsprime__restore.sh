#!/bin/bash

# let the script exit on errors (even within pipes), check for unset vars and disable globbing
# see https://sipb.mit.edu/doc/safe-shell
set -euf -o pipefail

echo

if [ "$#" -ne 1 ]; then
	echo "ERROR:"
	echo "Either .sql or .sql.bz2 file has to be given"
	exit 1
fi

# get the database env
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

HOST=$(python $SCRIPT_DIR/nmsprime_get_env.py host local)
USER=$(python $SCRIPT_DIR/nmsprime_get_env.py user local)
PASSWD=$(python $SCRIPT_DIR/nmsprime_get_env.py password local)
DB=$(python $SCRIPT_DIR/nmsprime_get_env.py db local)

CCC_HOST=$(python $SCRIPT_DIR/nmsprime_get_env.py host_ccc local)
CCC_USER=$(python $SCRIPT_DIR/nmsprime_get_env.py user_ccc local)
CCC_PASSWD=$(python $SCRIPT_DIR/nmsprime_get_env.py password_ccc local)
CCC_DB=$(python $SCRIPT_DIR/nmsprime_get_env.py db_ccc local)

CACTI_HOST=$(python $SCRIPT_DIR/nmsprime_get_env.py host_cacti local)
CACTI_USER=$(python $SCRIPT_DIR/nmsprime_get_env.py user_cacti local)
CACTI_PASSWD=$(python $SCRIPT_DIR/nmsprime_get_env.py password_cacti local)
CACTI_DB=$(python $SCRIPT_DIR/nmsprime_get_env.py db_cacti local)

ICINGA2_HOST=$(python $SCRIPT_DIR/nmsprime_get_env.py host_ccc local)
ICINGA2_USER=$(python $SCRIPT_DIR/nmsprime_get_env.py user_icinga2 local)
ICINGA2_PASSWD=$(python $SCRIPT_DIR/nmsprime_get_env.py password_icinga2 local)
ICINGA2_DB=$(python $SCRIPT_DIR/nmsprime_get_env.py db_icinga2 local)

# create the dump file in temp directory
if [[ "$1" == *.sql.bz2 ]]; then
	CAT_CMD="bzcat $1"

elif [[ "$1" == *.sql ]]; then
	CAT_CMD="cat $1"

elif [[ $1 == "-h" || $1 == "--help" ]]; then
	echo "Usage: $0 dumpfile"
	echo
	echo "       dumpfile has to be a *.sql or a *.sql.bz2 file"
	echo
	exit 0

else
	echo "ERROR:"
	echo "Either .sql or .sql.bz2 file has to be given"
	exit 1

fi

# special syntax ($') to be able to echo linebreaks
# functions can be listed by “SHOW FUNCTION STATUS”
NMSPRIME_DB_COMMANDS=$'
/* function needed by icingaweb2 to update netelements */
DROP FUNCTION IF EXISTS getTopParentNetelementType;
DELIMITER $$
CREATE FUNCTION getTopParentNetelementType(start_id INT) RETURNS INT DETERMINISTIC
BEGIN
  DECLARE x INT;
  DECLARE y INT;
  SET x = start_id;
  sloop:LOOP
    SELECT parent_id INTO y FROM netelementtype WHERE id = x;
    IF y IS NULL OR y = 0 THEN
      LEAVE sloop;
    END IF;
    SET x = y;
    ITERATE sloop;
  END LOOP;
  RETURN x;
END $$
DELIMITER ;
'

# restore the database
if [[ "$1" == *$CCC_DB.sql* ]]; then
	echo "Restoring database $CCC_DB…"
	$CAT_CMD | mysql -u $CCC_USER -h $CCC_HOST -p$CCC_PASSWD -D $CCC_DB
elif [[ "$1" == *$CACTI_DB.sql* ]]; then
	echo "Restoring database $CACTI_DB…"
	$CAT_CMD | mysql -u $CACTI_USER -h $CACTI_HOST -p$CACTI_PASSWD -D $CACTI_DB
elif [[ "$1" == *$DB.sql* ]]; then
	echo "Restoring database $DB…"
	$CAT_CMD | mysql -u $USER -h $HOST -p$PASSWD -D $DB

	# execute the SQL command(s); attention: “"” are needed in echo command to print line breaks!
	echo "Executing SQL commands…"
	echo "$NMSPRIME_DB_COMMANDS" | mysql -u $USER -h $HOST -p$PASSWD -D $DB
else
	echo "ERROR: filename $1 not matching *$CCC_DB.sql* or *$DB.sql*"
	echo "Nothing restored!"
	exit 1
fi

echo "Success"

echo
exit 0
