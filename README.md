# Official Grav Docker Image

This currently is pretty minimal and uses:

* apache-2.4.8
* GD library
* Unzip library
* php7.2
* php7.2-opcache
* php7.2-acpu
* php7.2-yaml

## Building the image from Dockerfile

```
docker build -t grav:latest .
```

## Running Grav Image with Latest Grav + Admin (not persistent):

```
docker run -p 8000:80 grav:latest
```

Point browser to `http://localhost/8000` and create user account...

## Running local Grav installation

This assumes you have already downloaded a Grav package into a local folder. This is the best way to run Grav if you want to have your changes persisted between restarts of the docker container.

```
docker run -v /local/grav/install:/var/www/html:cached -p 8000:80/tcp grav:latest
```

To run in the current directory you can use:

```
docker run -v `pwd`:/var/www/html:cached -p 8000:80/tcp grav:latest
```

Point browser to `http://localhost/8000` to access your Grav site