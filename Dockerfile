FROM alpine

# Initial updates
RUN apk update && \
    apk upgrade && \
    rm -rf /var/cache/apk/* /var/log/*

# Install packages
RUN apk add --no-cache \
    apache2 \
    apache2-proxy \
    php7-fpm \
    php7 \
    php7-apcu \
    php7-curl \
    php7-ctype \
    php7-dom \
    php7-common \
    php7-gd \
    php7-iconv \
    php7-json \
    php7-mbstring \
    php7-pecl-memcached \
    php7-openssl \
    php7-opcache \
    php7-pdo \
    php7-phar \
    php7-session \
    php7-simplexml \
    php7-soap \
    php7-xdebug \
    php7-xml \
    php7-pecl-yaml \
    php7-zip \
    composer \
    grep \
    git \
    curl \
    vim \
    shadow

# Configure to use php fpm and don't use /var/www to store everything (modules and logs)
RUN sed -i 's/LoadModule mpm_prefork_module/#LoadModule mpm_prefork_module/g' /etc/apache2/httpd.conf && \
    sed -i 's/#LoadModule mpm_event_module/LoadModule mpm_event_module/g' /etc/apache2/httpd.conf && \
    sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/g' /etc/apache2/httpd.conf && \
    # remove useless module bundled with proxy
    sed -i 's/LoadModule lbmethod/#LoadModule lbmethod/g' /etc/apache2/conf.d/proxy.conf && \
    # Enable deflate
    sed -i 's/#LoadModule deflate_module/LoadModule deflate_module/g' /etc/apache2/httpd.conf && \
    # Disable some configs
    sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php7/php.ini && \
    sed -i 's/expose_php = On/expose_php = Off/g' /etc/php7/php.ini && \
    # Prepare env
    mkdir -p /var/log/apache2 && \
    # Clean base directory and create required ones
    rm -rf /var/www/* && \
    mkdir -p /run/apache2 /usr/local/apache && \
    ln -s /usr/lib/apache2 /usr/local/apache/modules && \
    ln -s /var/log/apache2 /usr/local/apache/logs

COPY vhost.conf /etc/apache2/conf.d/vhost.conf

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

RUN chown -R apache:apache /var/log/apache2 /var/www

# Accept incoming HTTP requests
EXPOSE 80

# Return to root user
USER root

# provide container inside image for data persistence
VOLUME ["/var/www"]

COPY run.sh /run.sh
RUN chmod u+x /run.sh

CMD ["/run.sh"]