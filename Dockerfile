FROM php:7.4-fpm-alpine

# Initial updates
RUN apk update && \
    apk upgrade && \
    rm -rf /var/cache/apk/* /var/log/*

# Install packages
RUN apk add apache2 apache2-proxy shadow composer zip curl

# Configure to use php fpm and don't use /var/www to store everything (modules and logs)
RUN sed -i 's/LoadModule mpm_prefork_module/#LoadModule mpm_prefork_module/g' /etc/apache2/httpd.conf && \
    sed -i 's/#LoadModule mpm_event_module/LoadModule mpm_event_module/g' /etc/apache2/httpd.conf && \
    sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/g' /etc/apache2/httpd.conf && \
    # remove useless module bundled with proxy
    sed -i 's/LoadModule lbmethod/#LoadModule lbmethod/g' /etc/apache2/conf.d/proxy.conf && \
    # change ServerRoot
    sed -i 's/var\/www\/localhost\/htdocs/var\/www/g' /etc/apache2/httpd.conf && \
    sed -i 's/ServerRoot \/var\/www/ServerRoot \/usr\/local\/apache/g' /etc/apache2/httpd.conf && \
    # change user and group
    sed -i 's/^User apache/User www-data/g' /etc/apache2/httpd.conf && \
    sed -i 's/^Group apache/Group www-data/g' /etc/apache2/httpd.conf && \
    # Prepare env and create user
    mkdir -p /var/log/apache2 && \
    chown www-data:www-data /var/log/apache2 /var/www && \
    # Clean base directory and create required ones
    rm -rf /var/www/* && \
    mkdir -p /usr/local/apache && \
    ln -s /usr/lib/apache2 /usr/local/apache/modules && \
    ln -s /var/log/apache2 /usr/local/apache/logs

COPY vhost.conf /etc/apache2/conf.d/vhost.conf

ENV APACHE_UID  100
ENV APACHE_GID  101

# Define Grav specific version of Grav or use latest stable
ENV GRAV_VERSION latest

# Install grav
WORKDIR /var/www
RUN curl -o grav-admin.zip -SL https://getgrav.org/download/core/grav-admin/${GRAV_VERSION} && \
    unzip grav-admin.zip && \
    mv -f /var/www/grav-admin /var/www/html && \
    rm grav-admin.zip

# Create cron job for Grav maintenance scripts
RUN (crontab -l; echo "* * * * * cd /var/www/html;/usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -

# Accept incoming HTTP requests
EXPOSE 80/tcp

# Return to root user
USER root

# provide container inside image for data persistence
VOLUME ["/var/www"]

COPY        run.sh     /run.sh
RUN         chmod u+x  /run.sh

CMD         ["/run.sh"]