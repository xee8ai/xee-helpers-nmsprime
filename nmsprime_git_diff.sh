#!/bin/bash

DIFF_DIR="/root/git_diffs_nmsprime"
DIFF_FILE="$DIFF_DIR/nmsprime_$(date -Iseconds)_git.diff"
mkdir -p $DIFF_DIR
echo
echo "Diff can be found in $DIFF_FILE"

cd /var/www/nmsprime/ && git status | grep ".php" | grep geändert | cut -d ":" -f 2-2 | xargs git diff > $DIFF_FILE

echo
