FROM nginx:latest
LABEL maintainer="gushmazuko <gushmazuko@protonmail.com>"
LABEL description="Docker Image for Grav based on NGINX"

# Install dependencies
RUN apt update && apt install -y --no-install-recommends \
    vim\
    zip \
    unzip \
    git \
    php-fpm \
    php-cli \
    php-gd \
    php-curl \
    php-mbstring \
    php-xml \
    php-zip \
    php-apcu \
    cron

# Configure PHP FPM
# https://learn.getgrav.org/17/webservers-hosting/vps/digitalocean#configure-php7-2-fpm
RUN sed -i "s/.*cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php/7.*/fpm/php.ini

# Set user to www-data
RUN chown www-data:www-data /usr/share/nginx
RUN rm -rf /usr/share/nginx/html
USER www-data

# Define a specific version of Grav or use latest stable
ENV GRAV_VERSION latest

# Install grav
WORKDIR /usr/share/nginx
RUN curl -o grav-admin.zip -SL https://getgrav.org/download/core/grav-admin/${GRAV_VERSION} && \
    unzip grav-admin.zip && \
    mv -T /usr/share/nginx/grav-admin /usr/share/nginx/html && \
    rm grav-admin.zip

# Create cron job for Grav maintenance scripts
# https://learn.getgrav.org/17/advanced/scheduler
RUN (crontab -l; echo "* * * * * cd /usr/share/nginx/html;/usr/bin/php bin/grav scheduler 1>> /dev/null 2>&1") | crontab -

# Return to root user
USER root

# Add nginx to www-data group
RUN usermod -aG www-data nginx

# Replace dafault config files by provided by Grav
# https://learn.getgrav.org/17/webservers-hosting/vps/digitalocean#configure-nginx-connection-pool
RUN rm /etc/php/7.3/fpm/pool.d/www.conf
RUN rm /etc/nginx/conf.d/default.conf
COPY conf/php/grav.conf /etc/php/7.3/fpm/pool.d/
COPY conf/nginx/grav.conf /etc/nginx/conf.d/

# Provide container inside image for data persistence
VOLUME ["/usr/share/nginx/html"]

# Run startup script
CMD bash -c "service php7.3-fpm start && nginx -g 'daemon off;'"
