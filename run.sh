#!/bin/sh

# Allow apache user login
sed -i 's/apache(.*)\/sbin\/nologin/apache\\1\/bin\/ash/g' /etc/passwd
# Make sure apache can read&right to docroot
chown -R apache:apache /var/www
# Make sure apache can read&right to logs
chown -R apache:apache /var/log/apache2
# Allow Apache to create pid
chown -R apache:apache /run/apache2