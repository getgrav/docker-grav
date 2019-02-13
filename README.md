# Docker Image for Grav

_[Based on official grav docker image](https://github.com/getgrav/docker-grav)_

**Grav version : 1.5.3**

Fonctionnalities :

  * apache-2.4.8
  * GD library
  * Unzip library
  * php7.2
  * php7.2-opcache
  * php7.2-acpu
  * php7.2-yaml
  * php7.2-ldap

## Building the image from Dockerfile

```
docker build -t grav:latest .
```

## Running

You can find 2 version of this image, one on [gitlab botux-fr/docker/grav](https://gitlab.com/botux-fr/docker/grav) _with the CI tools_, the other on docker-hub, link to the [github repository boTux-fr/docker-grav](https://github.com/boTux-fr/docker-grav).

  * Latest botux-grav image on gitlab : [Grav images @ gitlab](https://gitlab.com/botux-fr/docker/grav/container_registry).
  * Other version on hub.docker : [Grav images @ docker hub](https://hub.docker.com/r/botux/grav/)

### Running Grav Image with Latest Grav + Admin (not persistent):

    docker run -p 8000:80 registry.gitlab.com/botux-fr/docker/grav:latest

Point browser to `http://localhost/8000` and create user account...

### With docker-compose : 

```yaml
version: "3.6"

services:
  grav:
    image: registry.gitlab.com/botux-fr/docker/grav:latest
    restart: always
    ports:
      - 8080:80
    volumes:
      - ./data/:/var/www/html/
```
_And go on http://localhost:8080/_

--------------------
#### docker-compose and a reverse proxy like traefik

If you're using traefik as reverse proxy, you can use : 

```yaml
version: "3.6"

networks:
  reverse-proxy:
    name: reverse-proxy
    external: true

services:
  grav:
    image: registry.gitlab.com/botux-fr/docker/grav:latest
    restart: always
    networks:
      - reverse-proxy
    labels:
      - "traefik.docker.network=reverse-proxy"
      - "traefik.enable=true"
      - "traefik.port=80"
      - "traefik.backend=grav"
      - "traefik.frontend.passHostHeader=true"
      - "traefik.frontend.rule=Host:${DOMAIN:-my.domain.tld}"
      - "traefik.frontend.whiteList.sourceRange=${WHITELIST:-}"
    volumes:
      - ./data/:/var/www/html/
```