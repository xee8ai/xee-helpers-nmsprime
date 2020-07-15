#!/bin/bash

cd /var/www/nmsprime

composer require barryvdh/laravel-debugbar --dev
composer require "squizlabs/php_codesniffer=*" --dev

git checkout -- composer.json

vim vendor/barryvdh/laravel-debugbar/config/debugbar.php
