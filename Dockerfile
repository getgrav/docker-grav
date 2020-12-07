FROM alpine:latest

# Initial updates
RUN apk update && \
    apk upgrade && \
    rm -rf /var/cache/apk/* /var/log/*

# Install packages
RUN apk add --no-cache \
    bash \
    busybox-suid \
    # Init related
    tini \
    openrc \
    busybox-initscripts \
    # Required packages
    composer \
    grep \
    git \
    curl \
    vim \
    shadow \
    supervisor \
    inotify-tools \
    # PHP related
    php7 \
    php7-pcntl

# Syslog option '-Z' was changed to '-t', change this in /etc/conf.d/syslog so that syslog (and then cron) actually starts
# https://gitlab.alpinelinux.org/alpine/aports/-/issues/9279
RUN sed -i 's/SYSLOGD_OPTS="-Z"/SYSLOGD_OPTS="-t"/g' /etc/conf.d/syslog

# AMPHP
RUN mkdir -p /var/www && \
    cd /var/www && \
    composer require amphp/http-server amphp/http-server-router amphp/http-server-static-content

# Accept incoming HTTP requests
EXPOSE 80

# Provide container inside image for data persistence
VOLUME ["/var/www"]

COPY example.php /var/www

CMD cd /var/www && php server.php
