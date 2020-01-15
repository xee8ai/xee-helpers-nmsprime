#!/bin/bash

source scl_source enable rh-php71

# helper to show how to use the script
function usage {
	echo
	echo "Usage: $0 [seed|noseed]"
	echo "	seed:   Fill database with random data"
	echo "	noseed: Only run the migrations"
	echo
}

# check the CLI arguments
if [ "$#" -ne 1 ]; then
	usage
	exit 1
fi

case "$1" in
	seed)
		SEED=true
		;;
	noseed)
		SEED=false
		;;
	*)
		usage
		exit 1
esac


PROJECT_DIR="/var/www/nmsprime/"
MODULES_DIR="/var/www/nmsprime/modules"
DATABASE_DIR="/var/lib/mysql/nmsprime"
CCC_DATABASE_DIR="/var/lib/mysql/nmsprime_ccc"

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CUR_DIR=$(pwd)

# first: backup the current state to prevent data loss
~/bin/database__nmsprime__dump.sh autodump_before_database_refresh

DB=$(python $SCRIPT_DIR/nmsprime_get_env.py db local)
CCC_DB=$(python $SCRIPT_DIR/nmsprime_get_env.py db_ccc local)

HOST=$(python $SCRIPT_DIR/nmsprime_get_env.py host local)
CCC_HOST=$(python $SCRIPT_DIR/nmsprime_get_env.py host_ccc local)

USER=$(python $SCRIPT_DIR/nmsprime_get_env.py user local)
CCC_USER=$(python $SCRIPT_DIR/nmsprime_get_env.py user_ccc local)

PASSWD=$(python $SCRIPT_DIR/nmsprime_get_env.py password local)
CCC_PASSWD=$(python $SCRIPT_DIR/nmsprime_get_env.py password_ccc local)

clear
cd $PROJECT_DIR

MODULES=$(ls -1 $MODULES_DIR)

# nmsprime_ccc
CCC_TABLES=$(python $SCRIPT_DIR/nmsprime_get_tables.py $CCC_DATABASE_DIR)
if [ ${#CCC_TABLES} -gt 0 ]; then
	# drop twice to get rid of all tables
	echo "DROP TABLE IF EXISTS $CCC_TABLES"
	mysql -u $CCC_USER -p$CCC_PASSWD -D $CCC_DB -e "DROP TABLE IF EXISTS $CCC_TABLES;"
	echo "DROP TABLE IF EXISTS $CCC_TABLES"
	mysql -u $CCC_USER -p$CCC_PASSWD -D $CCC_DB -e "DROP TABLE IF EXISTS $CCC_TABLES;"
	echo
fi

unlink /etc/raddb/mods-enabled/sql

php artisan migrate:fresh
php artisan module:migrate ProvBase
php artisan module:migrate BillingBase
php artisan module:migrate ProvMon
php artisan module:migrate ProvVoip
php artisan module:migrate ProvVoipEnvia
php artisan module:migrate HfcReq
php artisan module:migrate HfcBase
php artisan module:migrate HfcCustomer
php artisan module:migrate

if [ $SEED = true ]; then
	echo
	echo "Seeding globally…"
	php artisan -vvv db:seed
fi

if [ $SEED = true ]; then
	echo
	echo "Seeding modules…"
	php artisan -vvv module:seed
fi

echo
exit 0
# nmsprime
TABLES=$(python $SCRIPT_DIR/nmsprime_get_tables.py $DATABASE_DIR)
if [ ${#TABLES} -gt 0 ]; then
	# drop twice to get rid of all tables
	echo "DROP TABLE IF EXISTS $TABLES"
	mysql -u $USER -p$PASSWD -D $DB -e "DROP TABLE IF EXISTS $TABLES;"
	echo "DROP TABLE IF EXISTS $TABLES"
	mysql -u $USER -p$PASSWD -D $DB -e "DROP TABLE IF EXISTS $TABLES;"
	echo
fi

# nmsprime_ccc
CCC_TABLES=$(python $SCRIPT_DIR/nmsprime_get_tables.py $CCC_DATABASE_DIR)
if [ ${#CCC_TABLES} -gt 0 ]; then
	# drop twice to get rid of all tables
	echo "DROP TABLE IF EXISTS $CCC_TABLES"
	mysql -u $CCC_USER -p$CCC_PASSWD -D $CCC_DB -e "DROP TABLE IF EXISTS $CCC_TABLES;"
	echo "DROP TABLE IF EXISTS $CCC_TABLES"
	mysql -u $CCC_USER -p$CCC_PASSWD -D $CCC_DB -e "DROP TABLE IF EXISTS $CCC_TABLES;"
	echo
fi

# completely remove databases and user
# mysql -u $USER -p$PASSWD -e "DROP USER '$CCC_USER'@'$CCC_HOST'"
# mysql -u $USER -p$PASSWD -e "DROP DATABASE IF EXISTS $CCC_DB"

# # and create
# mysql -u $USER -p$PASSWD -e "CREATE DATABASE $CCC_DB;"
# mysql -u $USER -p$PASSWD -e "GRANT ALL ON $CCC_DB.* TO '$CCC_USER'@'$CCC_HOST' IDENTIFIED BY '$CCC_PASSWD'";

# Migrations and seeders should be run as user apache – e.g. to set owner/group correct for CarrierCode hash file
echo
echo "Migrating globally…"
# sudo -u apache php artisan -vvv migrate --force && sudo -u apache php artisan -v db:seed --class AuthuserTableSeeder
php artisan -vvv migrate

