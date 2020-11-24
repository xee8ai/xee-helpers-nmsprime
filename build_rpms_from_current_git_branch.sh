#!/bin/bash

# fpm has to be installed:
#	https://github.com/jordansissel/fpm
#	https://fpm.readthedocs.io/en/latest/installing.html
#
#	yum install ruby-devel gcc make rpm-build rubygems
#	gem install --no-document fpm

SRC="/var/www/nmsprime"
DST="/var/www/rpm/nmsprime"
FPM="/usr/local/bin/fpm"

cd "$SRC"

echo
echo "Getting tags…"
git fetch -tp
echo "Done…"

echo
echo "There are the following tags in this repo:"
git tag

echo
echo "The following subdirs already exists:"
CMD="ls -l $DST"
echo $CMD
$CMD

echo
read -p "Which RPM version you want to build (e.g. 2.4.1)? " RPMVERSION

DST="$DST/$RPMVERSION"
mkdir -p "$DST"

echo
echo "Pulling repo…"
git pull

echo
echo "Updating submodules…"
git submodule update --init --recursive

echo
echo "Updating composer"
composer update
echo "Done…"

echo
echo "Creating RPMs…"
php Install/install.php "$RPMVERSION" . "$DST"
echo "Done…"
echo "RPMs went to $DST:"
ls -l "$DST"
echo
