# Docker Grav based on NGINX
![https://hub.docker.com/r/gushmazuko/docker-grav-nginx](https://img.shields.io/docker/cloud/build/gushmazuko/grav-nginx.svg) ![https://hub.docker.com/r/gushmazuko/docker-grav-nginx](https://img.shields.io/docker/cloud/automated/gushmazuko/grav-nginx.svg)

## Persisting data
To save the Grav site data to the host file system (so that it persists even after the container has been removed), simply map the container's `/usr/share/nginx/html` directory to a named Docker volume or to a directory on the host.

> If the mapped directory or named volume is empty, it will be automatically populated with a fresh install of Grav the first time that the container starts. However, once the directory/volume has been populated, the data will persist and will not be overwritten the next time the container starts.

## Building the image from Dockerfile
```
docker build -t gushmazuko/grav-nginx:latest .
```

## Running Grav Image with Latest Grav + Admin with a named volume (can be used in production)
```
docker run -d -p 8000:80 --restart always -v grav_data:/usr/share/nginx/html gushmazuko/grav-nginx:latest
```
Point browser to `http://localhost:8000` and create user account...

## Running Grav Image with docker-compose and a volume mapped to a local directory
Run `docker-compose up -d` with the following docker-compose configuration. Then the Grav container will be started with all of the site data persisted to a named volume (stored in the `./grav_data` directory).

```
version: "3.8"
services:
  grav:
    image: gushmazuko/grav-nginx:latest
    container_name: ${SERVICE}_grav
    restart: unless-stopped
    environment:
      TZ: ${TZ}
    ports:
      - 80:80
      - 443:443
    volumes:
      - grav:/usr/share/nginx/html
#      - ./conf/nginx/:/etc/nginx/conf.d/
#      - ./conf/php/:/etc/php/7.3/fpm/pool.d/
    networks:
      - web
networks:
  web:
    external: true
volumes:
  grav:
    driver: local
    driver_opts:
      type: none
      device: $PWD/grav_data
      o: bind
```

* Edit `.env` environment file
```
SERVICE=mysite
DOMAIN_NAME=example.com
SERVICE_PORT=80
TZ=Europe/Berlin
```

## Editing `NGINX` & `FPM` configuration (Optional)

* Uncomment theses lines in `docker-compose.yml`
```
#      - ./conf/nginx/:/etc/nginx/conf.d/
#      - ./conf/php/:/etc/php/7.3/fpm/pool.d/
```

* Then modify `NGINX` site config `./conf/nginx/grav.conf`

```
server {
    listen 80;
    index index.html index.php;

    ## Begin - Server Info
    root /usr/share/nginx/html;
    server_name gravsite;
    ## End - Server Info

    ## Begin - Index
    # for subfolders, simply adjust:
    # `location /subfolder {`
    # and the rewrite to use `/subfolder/index.php`
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }
    ## End - Index

    ## Begin - Security
    # deny all direct access for these folders
    location ~* /(\.git|cache|bin|logs|backup|tests)/.*$ { return 403; }
    # deny running scripts inside core system folders
    location ~* /(system|vendor)/.*\.(txt|xml|md|html|yaml|yml|php|pl|py|cgi|twig|sh|bat)$ { return 403; }
    # deny running scripts inside user folder
    location ~* /user/.*\.(txt|md|yaml|yml|php|pl|py|cgi|twig|sh|bat)$ { return 403; }
    # deny access to specific files in the root folder
    location ~ /(LICENSE\.txt|composer\.lock|composer\.json|nginx\.conf|web\.config|htaccess\.txt|\.htaccess) { return 403; }
    ## End - Security

    ## Begin - PHP
    location ~ \.php$ {
        # Choose either a socket or TCP/IP address
        fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
        # fastcgi_pass unix:/var/run/php5-fpm.sock; #legacy
        # fastcgi_pass 127.0.0.1:9000;

        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root/$fastcgi_script_name;
    }
    ## End - PHP
}
```
* And `FPM` config `./conf/php/grav.conf`

```
[grav]

user = www-data
group = www-data

listen = /var/run/php/php7.3-fpm.sock

listen.owner = www-data
listen.group = www-data

pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3

chdir = /
````

## Using `Traefik` instead `port mapping` (Optional)
* Comment theses lines in `docker-compose.yml`

```
ports:
  - 80:80
  - 443:443
```

* And add `Traefik` labels into `docker-compose.yml`  [More Info About](https://github.com/gushmazuko/dockers_template/tree/master/traefik)
```
labels:
  - "traefik.enable=true"
  # http
  - "traefik.http.routers.${SERVICE}.rule=Host(`${DOMAIN_NAME}`)"
  - "traefik.http.services.${SERVICE}.loadbalancer.server.port=${SERVICE_PORT}"
  - "traefik.http.routers.${SERVICE}_redirect.rule=Host(`${DOMAIN_NAME}`)"
  - "traefik.http.routers.${SERVICE}_redirect.entrypoints=web"
  # redirect to https
  - "traefik.http.routers.${SERVICE}.tls.certresolver=le"
  - "traefik.http.routers.${SERVICE}.entrypoints=web-secure"
  - "traefik.http.middlewares.${SERVICE}_https.redirectscheme.scheme=https"
  - "traefik.http.routers.${SERVICE}_redirect.middlewares=${SERVICE}_https"
```
