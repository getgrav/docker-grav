#!/bin/sh

# Start PHP-FPM in the background
php-fpm -D
# Start Apache
service httpd start