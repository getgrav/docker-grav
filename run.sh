#!/bin/sh

# Start PHP-FPM and Apache
exec /usr/sbin/httpd -D FOREGROUND -f /etc/apache2/httpd.conf &
exec /usr/sbin/php-fpm7 -F