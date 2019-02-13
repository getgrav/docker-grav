ARG PHP_VERSION=7.2

FROM php:${PHP_VERSION}-apache
LABEL maintainer="Andy Miller <rhuk@getgrav.org> (@rhukster)" \
      maintainer="Romain Fluttaz <romain@fluttaz.fr>"

# install dependencies we need
RUN set -ex; \
	\
	apt-get update; \
	apt-get install -y \
        unzip

# install the PHP extensions we need
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libyaml-dev \
        libldap2-dev \
	; \
	\
    pecl install apcu; \
    pecl install yaml; \
	docker-php-ext-enable apcu yaml; \
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
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \
        echo 'upload_max_filesize = 128M'; \
        echo 'post_max_size = 128M'; \
        echo 'max_execution_time = 600'; \
        echo 'max_input_vars = 5000'; \
    } > /usr/local/etc/php/conf.d/php-optimisations.ini


# Enable Apache Rewrite + Expires Module
RUN a2enmod rewrite expires

VOLUME /var/www/html

RUN chown -R www-data:www-data /var/www

# Define Grav version and expected SHA1 signature
ENV GRAV_VERSION 1.5.5
ENV GRAV_SHA1 af0433facdae1afeb1d973a66db2315c5022b10d

# Install grav
RUN set -ex; \
    curl -o grav-admin.zip -fSL https://getgrav.org/download/core/grav-admin/${GRAV_VERSION}; \
    echo "$GRAV_SHA1 grav-admin.zip" | sha1sum -c -; \
    # upstream tarballs include ./grav-admin/ so this gives us /usr/src/grav-admin
    unzip grav-admin.zip -d /usr/src/; \
    rm grav-admin.zip; \
    chown -R www-data:www-data /usr/src/grav-admin

# Return to root user
USER root

COPY entrypoint.sh /usr/local/bin/

ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]"]
