#!/bin/sh

# Make sure apache can read&right to docroot
chown -R apache:apache /var/www
# Make sure apache can read&right to logs
chown -R apache:apache /var/log/apache2

# syslog option '-Z' was changed to '-t', change this in /etc/conf.d/syslog so that syslog (and then cron) actually starts
# https://gitlab.alpinelinux.org/alpine/aports/-/issues/9279
sed -i 's/SYSLOGD_OPTS="-Z"/SYSLOGD_OPTS="-t"/g' /etc/conf.d/syslog
# Restart the syslog
rc-service syslog restart
# Restart the kernel log deamon
rc-service klogd restart

# Start the cron deamon by default
rc-update add crond default && rc-service crond start
# Start Apache by default
rc-update add httpd default && rc-service httpd start
# default PHP-FPM by default
rc-update add php-fpm7 default && rc-service php-fpm7 start

# Create cron job for Grav maintenance scripts
(crontab -l; echo "* * * * * cd /var/www/html;/usr/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -
# Cron requires that each entry in a crontab end in a newline character. If the last entry in a crontab is missing the newline, cron will consider the crontab (at least partially) broken and refuse to install it.
(crontab -l; echo "") | crontab -
