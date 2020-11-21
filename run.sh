#!/bin/sh

# Make sure apache can read&right to /var/www
RUN chown -R apache:apache /var/log/apache2 /var/www
# Start PHP-FPM and Apache
exec /usr/sbin/httpd -D FOREGROUND -f /etc/apache2/httpd.conf &
exec /usr/sbin/php-fpm7 -F