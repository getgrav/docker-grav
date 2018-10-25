# Docker Image for Grav

_[Based on official grav docker image](https://github.com/getgrav/docker-grav)_

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

## Running Grav Image with Latest Grav + Admin (not persistent):

```
docker run -p 8000:80 grav:latest
```

Point browser to `http://localhost/8000` and create user account...


