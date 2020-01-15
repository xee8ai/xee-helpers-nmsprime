#!/bin/bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

if [[ "$1" == ccc ]]; then
        USER=$(python $SCRIPT_DIR/nmsprime_get_env.py user_ccc local)
        PASSWD=$(python $SCRIPT_DIR/nmsprime_get_env.py password_ccc local)
        DB=$(python $SCRIPT_DIR/nmsprime_get_env.py db_ccc local)
elif [[ "$1" == cacti ]]; then
        USER=$(python $SCRIPT_DIR/nmsprime_get_env.py user_cacti local)
        PASSWD=$(python $SCRIPT_DIR/nmsprime_get_env.py password_cacti local)
        DB=$(python $SCRIPT_DIR/nmsprime_get_env.py db_cacti local)
else
        USER=$(python $SCRIPT_DIR/nmsprime_get_env.py user local)
        PASSWD=$(python $SCRIPT_DIR/nmsprime_get_env.py password local)
        DB=$(python $SCRIPT_DIR/nmsprime_get_env.py db local)
fi

mysql -u $USER -p$PASSWD -D $DB
