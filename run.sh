#!/bin/sh

# Start PHP-FPM in the background
php-fpm -F
# Start Apache
service httpd start