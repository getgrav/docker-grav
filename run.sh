#!/bin/sh

# syslog option '-Z' was changed to '-t', change this in /etc/conf.d/syslog so that syslog (and then cron) actually starts
# https://gitlab.alpinelinux.org/alpine/aports/-/issues/9279
exec sed -i 's/SYSLOGD_OPTS="-Z"/SYSLOGD_OPTS="-t"/g' /etc/conf.d/syslog
# Start the kernel log deamon
exec service klogd start
# Start the cron deamon
exec service crond start

# Create cron job for Grav maintenance scripts
(crontab -l; echo "* * * * * cd /var/www/html;/usr/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -
# Cron requires that each entry in a crontab end in a newline character. If the last entry in a crontab is missing the newline, cron will consider the crontab (at least partially) broken and refuse to install it.
(crontab -l; echo "") | crontab -

# Start Apache, PHP-FPM and Cron
exec /usr/sbin/httpd -D FOREGROUND -f /etc/apache2/httpd.conf &
exec /usr/sbin/php-fpm7 -F

# Make sure apache can read&right to logs and docroot
RUN chown -R apache:apache /var/log/apache2 /var/www
