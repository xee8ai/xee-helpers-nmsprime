#!/bin/bash

# fpm has to be installed:
#	https://github.com/jordansissel/fpm
#	https://fpm.readthedocs.io/en/latest/installing.html
#
#	yum install ruby-devel gcc make rpm-build rubygems
#	gem install --no-document fpm

SRC="/var/www/nmsprime"
DST="/var/www/rpm/nmsprime"
RPMBUILD="/var/www/repos/rpmbuild"
FPM="/usr/local/bin/fpm"

INSTALL_CONFIG_FILE="Install/config.cfg"


################################################################################
# Getting metadata and asking for version to build
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


################################################################################
# build the rpmbuild package (dependency of nmsprime)
echo
echo "Creating rpmbuild package"
cd "$RPMBUILD/SPECS"
git pull
sed -i 's/^Version: .*/Version: '$RPMVERSION'/g' $RPMBUILD/SPECS/nmsprime-repos.spec
rpmbuild -ba nmsprime-repos.spec


################################################################################
cd "$SRC"

echo
echo "Pulling repo…"
git pull

echo
echo "Updating submodules…"
git submodule update --init --recursive

echo
echo "Updating composer"
COMPOSER_MEMORY_LIMIT=-1 composer update
echo "Done…"

echo
echo "Removing ioncube dependency…"
sed -i "s/;php-ioncube-loader//" $INSTALL_CONFIG_FILE
git diff $INSTALL_CONFIG_FILE
echo "Done…"

echo
echo "Creating RPMs…"
php Install/install.php "$RPMVERSION" . "$DST"
echo "Done…"

echo
echo "Restoring original install config…"
git checkout -- $INSTALL_CONFIG_FILE
echo "Done…"

echo
echo "Copying rpmbuild package"
cp /root/rpmbuild/RPMS/noarch/*$RPMVERSION* $DST

echo
echo "RPMs went to $DST:"
ls -l "$DST"
echo
