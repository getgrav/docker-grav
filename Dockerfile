FROM php:7.4-apache
LABEL maintainer="Andy Miller <rhuk@getgrav.org> (@rhukster)"

# Enable Apache Rewrite + Expires Module
RUN a2enmod rewrite expires && \
    sed -i 's/ServerTokens OS/ServerTokens ProductOnly/g' \
    /etc/apache2/conf-available/security.conf

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libyaml-dev \
    libzip4 \
    libzip-dev \
    zlib1g-dev \
    libicu-dev \
    g++ \
    git \
    cron \
    vim \
    && docker-php-ext-install opcache \
    && docker-php-ext-configure intl \
    && docker-php-ext-install intl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip \
    && rm -rf /var/lib/apt/lists/*

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128; The size of the shared memory storage used by OPcache, in megabytes'; \
    echo 'opcache.interned_strings_buffer=8; The amount of memory used to store interned strings, in megabytes'; \
    echo 'opcache.max_accelerated_files=4000; The maximum number of keys (and therefore scripts) in the OPcache hash table'; \
    echo 'opcache.revalidate_freq=60; How often to check script timestamps for updates, in seconds. 0 will result in OPcache checking for updates on every request'; \
    echo 'opcache.enable_cli=1; Enables the opcode cache for the CLI version of PHP'; \
    echo 'upload_max_filesize=128M; The maximum size of an uploaded file'; \
    echo 'post_max_size=128M; Sets max size of post data allowed'; \
    echo 'expose_php=off; Exposes to the world that PHP is installed on the server, which includes the PHP version within the HTTP header'; \
    } > /usr/local/etc/php/conf.d/php-recommended.ini
# opcache.fast_shutdown - This directive has been removed in PHP 7.2.0. A variant of the fast shutdown sequence has been integrated into PHP and will be automatically used if possible.

# Additional, performance related configs
RUN { \
    echo 'memory_limit=2G; This sets the maximum amount of memory in bytes that a script is allowed to allocate. Set a high value for Dev envs or for Prod envs that use more than 1-2 background jobs. In today\'s real life, production apps should set this to at least 512M for medium to large websites.'; \
    echo 'opcache.enable_file_override=1; When enabled, the opcode cache will be checked for whether a file has already been cached when file_exists(), is_file() and is_readable() are called. This may increase performance in applications that check the existence and readability of PHP scripts, but risks returning stale data if opcache.validate_timestamps is disabled.'; \
    echo 'opcache.validate_timestamps=1; If enabled, OPcache will check for updated scripts every opcache.revalidate_freq seconds. When this directive is disabled, you must reset OPcache manually via opcache_reset(), opcache_invalidate() or by restarting the Web server for changes to the filesystem to take effect.'; \
    echo 'opcache.revalidate_path=1; If disabled, existing cached files using the same include_path will be reused. Thus, if a file with the same name is elsewhere in the include_path, it will not be found.'; \
    echo 'opcache.save_comments=1; If disabled, all documentation comments will be discarded from the opcode cache to reduce the size of the optimised code. Disabling this configuration directive may break applications and frameworks that rely on comment parsing for annotations, including Doctrine, Zend Framework 2 and PHPUnit.'; \
    echo 'opcache.use_cwd=1; If enabled, OPcache appends the current working directory to the script key, thereby eliminating possible collisions between files with the same base name. Disabling this directive improves performance, but may break existing applications.'; \
    } >> /usr/local/etc/php/conf.d/php-recommended.ini

RUN pecl install apcu \
    && pecl install yaml-2.0.4 \
    && docker-php-ext-enable apcu yaml gd

# Set user to www-data
RUN chown www-data:www-data /var/www
USER www-data

# Define Grav specific version of Grav or use latest stable
ENV GRAV_VERSION latest

# Install grav
WORKDIR /var/www
RUN curl -o grav-admin.zip -SL https://getgrav.org/download/core/grav-admin/${GRAV_VERSION} && \
    unzip grav-admin.zip && \
    mv -T /var/www/grav-admin /var/www/html && \
    rm grav-admin.zip

# Create cron job for Grav maintenance scripts
RUN (crontab -l; echo "* * * * * cd /var/www/html;/usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -

# Some folders will always be updated (e.g. logs) by Grav app, so they can be ignored from the Git repo
RUN { \
    echo '### Folders that need to exist but their contents are written by the server on the fly'; \
    echo '# Assets'; \
    echo 'assets/*'; \
    echo '!assets/.gitkeep'; \
    echo '# Images'; \
    echo 'images/*'; \
    echo '!images/.gitkeep'; \
    echo '# Logs'; \
    echo 'logs/*'; \
    echo '!logs/.gitkeep'; \
    echo '# User data'; \
    echo 'user/data/*'; \
    echo '!user/data/.gitkeep'; \
    echo '###'; \
    echo ''; \
    echo '# Ignore these completely'; \
    echo 'backup'; \
    echo 'cache'; \
    echo 'logs'; \
    echo 'tmp'; \
    } > /var/www/html/.gitignore

# Return to root user
USER root

# Copy init scripts
# COPY docker-entrypoint.sh /entrypoint.sh

# provide container inside image for data persistence
VOLUME ["/var/www/html"]

# ENTRYPOINT ["/entrypoint.sh"]
# CMD ["apache2-foreground"]
CMD ["sh", "-c", "cron && apache2-foreground"]
