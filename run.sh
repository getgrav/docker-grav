#!/bin/sh

# Start PHP-FPM and Apache
php-fpm -F && service httpd start