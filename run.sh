#!/bin/sh
CURRENT_APACHE_ID=$(id -u www-data)
if [ "$CURRENT_APACHE_ID" != "$APACHE_UID" ]; then
    echo "Fixing permissions for www-data"
    usermod -u $APACHE_UID www-data
    groupmod -g $APACHE_GID www-data
    chown -R www-data:www-data /run/apache2 /var/www
fi

exec /usr/sbin/httpd -DFOREGROUND;
