FROM php:7.2-apache
LABEL maintainer="Andy Miller <rhuk@getgrav.org> (@rhukster)" \
      maintainer="Romain Fluttaz <romain@fluttaz.fr>"

# install the PHP extensions we need
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
        unzip \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libyaml-dev \
        libldap2-dev \
	; \
	\
    pecl install apcu; \
    pecl install yaml; \
	docker-php-ext-install apcu yaml; \
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/; \
	docker-php-ext-install gd mysqli opcache zip ldap; \
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
	} > /usr/local/etc/php/conf.d/php-recommended.ini

# Enable Apache Rewrite + Expires Module
RUN a2enmod rewrite expires

# VOLUME /var/www/html

# Set user to www-data
RUN chown www-data:www-data /var/www
USER www-data

# Define Grav version and expected SHA1 signature
ENV GRAV_VERSION 1.5.1
ENV GRAV_SHA1 5292b05d304329beefeddffbf9f542916012c221

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
