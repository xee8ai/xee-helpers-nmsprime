#!/bin/bash

# Helper to clean environment if there are strange problems
# like ExtendedValidator not found or wrongly built URLs like https://localhost/admin/Contract/create
# if that doesn't help try deleting bootstrap/cache/*

cd /var/www/nmsprime

export COMPOSER_MEMORY_LIMIT=-1
export COMPOSER_ALLOW_SUPERUSER=1

mkdir -p /var/www/nmsprime/storage/framework/cache
mkdir -p /var/www/nmsprime/storage/framework/sessions
mkdir -p /var/www/nmsprime/storage/framework/views

composer update
php artisan migrate
php artisan module:migrate
php artisan module:publish
php artisan optimize

systemctl restart supervisord httpd
systemctl restart telegraf

chown -R apache /var/www/nmsprime/storage/framework

rm -rf public/js/ && rm -rf public/css/ && rm -f public/mix-manifest.json && npm i && npm run dev
