#!/bin/sh

# Create cron job for Grav maintenance scripts
(crontab -l; echo "* * * * * cd /var/www/html;/usr/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -
# Cron requires that each entry in a crontab end in a newline character. If the last entry in a crontab is missing the newline, cron will consider the crontab (at least partially) broken and refuse to install it.
(crontab -l; echo "") | crontab -

# Start Apache and PHP-FPM
exec /usr/sbin/httpd -D FOREGROUND -f /etc/apache2/httpd.conf &
exec /usr/sbin/php-fpm7 -F