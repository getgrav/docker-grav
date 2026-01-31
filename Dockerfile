# =============================================================================
# Grav CMS Docker Image
# =============================================================================
# Build arguments:
#   PHP_VERSION          - PHP version (default: 8.3)
#   PHP_EXTENSIONS       - Core extensions (default: opcache intl gd zip)
#   PHP_EXTRA_EXTENSIONS - Additional extensions (default: empty)
#   GRAV_VERSION         - Grav version to install (default: latest)
#
# Examples:
#   docker build -t grav .
#   docker build --build-arg PHP_VERSION=8.4 -t grav:php84 .
#   docker build --build-arg PHP_EXTRA_EXTENSIONS="xdebug redis" -t grav:dev .
# =============================================================================

ARG PHP_VERSION=8.3
FROM php:${PHP_VERSION}-apache-bookworm

LABEL maintainer="Andy Miller <rhuk@getgrav.org> (@rhukster)"
LABEL org.opencontainers.image.source="https://github.com/getgrav/docker-grav"
LABEL org.opencontainers.image.description="Grav CMS Docker Image"

# Build arguments for PHP extensions
ARG PHP_EXTENSIONS="opcache intl gd zip"
ARG PHP_EXTRA_EXTENSIONS=""
ARG GRAV_VERSION=latest

# Environment variables
ENV GRAV_VERSION=${GRAV_VERSION} \
    GRAV_SETUP=true \
    GRAV_SCHEDULER=true \
    FIX_PERMISSIONS=false

# =============================================================================
# System Setup
# =============================================================================

# Enable Apache modules
RUN a2enmod rewrite expires headers

# Harden Apache configuration
RUN sed -i 's/ServerTokens OS/ServerTokens ProductOnly/g' \
        /etc/apache2/conf-available/security.conf && \
    sed -i 's/ServerSignature On/ServerSignature Off/g' \
        /etc/apache2/conf-available/security.conf

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip \
    cron \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# =============================================================================
# PHP Extensions (using docker-php-extension-installer)
# =============================================================================

# Install docker-php-extension-installer for reliable extension management
# https://github.com/mlocati/docker-php-extension-installer
ADD --chmod=755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Install core PHP extensions required by Grav
RUN install-php-extensions ${PHP_EXTENSIONS}

# Install PECL extensions (apcu, yaml)
RUN install-php-extensions apcu yaml

# Install extra extensions if specified
RUN if [ -n "${PHP_EXTRA_EXTENSIONS}" ]; then \
        install-php-extensions ${PHP_EXTRA_EXTENSIONS}; \
    fi

# =============================================================================
# PHP Configuration
# =============================================================================

# Copy Grav-optimized PHP settings
COPY config/php-grav.ini /usr/local/etc/php/conf.d/php-grav.ini

# =============================================================================
# Entrypoint Setup
# =============================================================================

# Copy and configure entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create directory for custom initialization scripts
RUN mkdir -p /docker-entrypoint.d

# Set up web root
RUN chown -R www-data:www-data /var/www/html

# =============================================================================
# Runtime Configuration
# =============================================================================

WORKDIR /var/www/html

# Expose HTTP port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Volume for Grav site data
VOLUME ["/var/www/html"]

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
