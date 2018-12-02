FROM php:7.2-apache
LABEL maintainer="Andy Miller <rhuk@getgrav.org> (@rhukster)"

# Enable Apache Rewrite + Expires Module
RUN a2enmod rewrite expires

# Install dependencies
RUN apt-get update && apt-get install -y \
        unzip \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libyaml-dev \
    && docker-php-ext-install opcache \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip

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
	} > /usr/local/etc/php/conf.d/php-recommended.ini

 # provide container inside image for data persistance
# VOLUME /var/www/html

RUN pecl install apcu \
    && pecl install yaml \
    && docker-php-ext-enable apcu yaml

# Set user to www-data
RUN chown www-data:www-data /var/www
USER www-data

# Define Grav version and expected SHA1 signature
ENV GRAV_VERSION 1.5.5
ENV GRAV_SHA1 af0433facdae1afeb1d973a66db2315c5022b10d

# Install grav
WORKDIR /var/www
RUN curl -o grav-admin.zip -SL https://getgrav.org/download/core/grav-admin/${GRAV_VERSION} && \
    echo "$GRAV_SHA1 grav-admin.zip" | sha1sum -c - && \
    unzip grav-admin.zip && \
    mv -T /var/www/grav-admin /var/www/html && \
    rm grav-admin.zip

# Return to root user
USER root

# Copy init scripts
# COPY docker-entrypoint.sh /entrypoint.sh

# ENTRYPOINT ["/entrypoint.sh"]
# CMD ["apache2-foreground"]
