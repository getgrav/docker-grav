#!/bin/sh

# syslog option '-Z' was changed to '-t', change this in /etc/conf.d/syslog so that syslog (and then cron) actually starts
# https://gitlab.alpinelinux.org/alpine/aports/-/issues/9279
sed -i 's/SYSLOGD_OPTS="-Z"/SYSLOGD_OPTS="-t"/g' /etc/conf.d/syslog
# Start the kernel log deamon
service klogd start
# Start the cron deamon
service crond start

# Create cron job for Grav maintenance scripts
(crontab -l; echo "* * * * * cd /var/www/html;/usr/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -
# Cron requires that each entry in a crontab end in a newline character. If the last entry in a crontab is missing the newline, cron will consider the crontab (at least partially) broken and refuse to install it.
(crontab -l; echo "") | crontab -

# Start Apache
service httpd start
# Start PHP-FPM
service php-fpm7 start
