#!/bin/sh

# Make sure apache can read&right to /var/www
chown -R apache:apache /var/log/apache2 /var/www

# Create cron job for Grav maintenance scripts
(crontab -l; echo "* * * * * cd /var/www/html;/usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -

# Start PHP-FPM and Apache
exec /usr/sbin/httpd -D FOREGROUND -f /etc/apache2/httpd.conf &
exec /usr/sbin/php-fpm7 -F