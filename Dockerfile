FROM php:7.3-apache
LABEL maintainer="Andy Miller <rhuk@getgrav.org> (@rhukster)"

# runtime dependencies
RUN set -ex; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        busybox \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    \
    mkdir -p /var/spool/cron/crontabs; \
    echo '* * * * * php -f /var/www/html/bin/grav scheduler 1>> /dev/null 2>&1' > /var/spool/cron/crontabs/www-data

# Enable Apache Rewrite + Expires Module
RUN a2enmod rewrite expires && \
    sed -i 's/ServerTokens OS/ServerTokens ProductOnly/g' \
    /etc/apache2/conf-available/security.conf

RUN set -ex; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libpng-dev \
        libyaml-dev \
        libzip-dev \
    ; \
    \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j "$(nproc)" \
        gd \
        intl \
        opcache \
        zip \
    ; \
    \
# pecl will claim success even if one install fails, so we need to perform each install separately
    pecl install APCu-5.1.18; \
    pecl install yaml-2.0.4; \
    \
    docker-php-ext-enable \
        apcu \
        yaml \
    ; \
    \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
        | awk '/=>/ { print $3 }' \
        | sort -u \
        | xargs -r dpkg-query -S \
        | cut -d: -f1 \
        | sort -u \
        | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    echo 'upload_max_filesize=128M'; \
    echo 'post_max_size=128M'; \
    echo 'expose_php=off'; \
    } > /usr/local/etc/php/conf.d/php-recommended.ini

# Define Grav specific version of Grav or use latest stable
ENV GRAV_VERSION latest

# Install grav
RUN set -ex; \
    curl -o grav-admin.zip -fsSL https://getgrav.org/download/core/grav-admin/${GRAV_VERSION}; \
    busybox unzip -qd /var/www grav-admin.zip; \
    rm -r /var/www/html; \
    mv -T /var/www/grav-admin /var/www/html; \
    chown www-data:www-data -R /var/www/html

# Copy init scripts
# COPY docker-entrypoint.sh /entrypoint.sh

# provide container inside image for data persistence
VOLUME ["/var/www/html"]

# ENTRYPOINT ["/entrypoint.sh"]
# CMD ["apache2-foreground"]
CMD ["sh", "-c", "busybox crond && apache2-foreground"]
