# Grav CMS Docker Image

[![Docker Pulls](https://img.shields.io/docker/pulls/getgrav/grav.svg)](https://hub.docker.com/r/getgrav/grav)
[![Docker Stars](https://img.shields.io/docker/stars/getgrav/grav.svg)](https://hub.docker.com/r/getgrav/grav)

Official Docker image for [Grav CMS](https://getgrav.org) - a modern, fast, and flexible flat-file content management system.

## Supported Tags

- `latest`, `1.7`, `php8.3` - Grav with PHP 8.3 (default)
- `php8.5` - Grav with PHP 8.5 (latest PHP)
- `php8.4` - Grav with PHP 8.4

## Quick Start

```bash
# Pull and run
docker run -d -p 8080:80 -v grav_site:/var/www/html getgrav/grav

# Open browser
open http://localhost:8080
```

That's it! Grav will be automatically installed on first run.

### With Docker Compose

```yaml
services:
  grav:
    image: getgrav/grav
    ports:
      - "8080:80"
    volumes:
      - grav_site:/var/www/html
    restart: unless-stopped

volumes:
  grav_site:
```

```bash
docker compose up -d
```

### With Local Directory

```bash
# Create a directory for your site
mkdir my-grav-site

# Run with bind mount
docker run -d -p 8080:80 -v ./my-grav-site:/var/www/html getgrav/grav
```

## Features

- **Auto-install** - Grav is automatically installed on first run if the volume is empty
- **Grav Scheduler** - Cron job for Grav's scheduler is pre-configured
- **Health Check** - Built-in health check for container orchestration
- **Customizable** - Easy to add PHP extensions via build args

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GRAV_SETUP` | `true` | Auto-install Grav if volume is empty |
| `GRAV_CHANNEL` | `stable` | Release channel: `stable` or `beta` |
| `GRAV_SCHEDULER` | `true` | Enable Grav scheduler cron job |
| `FIX_PERMISSIONS` | `false` | Fix file permissions on startup |

## Configuration

### Installing Grav Beta

To install the latest Grav 1.8 beta:

```bash
docker run -d -p 8080:80 -e GRAV_CHANNEL=beta -v grav_site:/var/www/html getgrav/grav
```

Or with Docker Compose:

```yaml
services:
  grav:
    image: getgrav/grav
    environment:
      - GRAV_CHANNEL=beta
    volumes:
      - grav_site:/var/www/html
```

### Using an Existing Grav Site

Mount your existing Grav installation:

```bash
docker run -d -p 8080:80 -v /path/to/your/grav:/var/www/html getgrav/grav
```

The container detects existing installations and skips the auto-install.

### Fixing Permissions

If you encounter permission errors:

```bash
docker run -d -p 8080:80 \
  -e FIX_PERMISSIONS=true \
  -v ./my-site:/var/www/html \
  getgrav/grav
```

Or fix manually:

```bash
docker exec <container> chown -R www-data:www-data /var/www/html
```

## Building Custom Images

### Different PHP Version

```bash
# Clone the repository
git clone https://github.com/getgrav/docker-grav.git
cd docker-grav

# Build with PHP 8.4
docker build --build-arg PHP_VERSION=8.4 -t grav:php84 .
```

### Additional PHP Extensions

Default extensions: `opcache`, `intl`, `gd`, `zip`, `apcu`, `yaml`

Add more:

```bash
# Add Xdebug for development
docker build --build-arg PHP_EXTRA_EXTENSIONS="xdebug" -t grav:dev .

# Add Redis and Imagick
docker build --build-arg PHP_EXTRA_EXTENSIONS="redis imagick" -t grav:custom .
```

### Specific Grav Version

```bash
docker build --build-arg GRAV_VERSION=1.7.45 -t grav:1.7.45 .
```

### Extending the Image

```dockerfile
FROM getgrav/grav:latest

# Install additional PHP extensions
RUN install-php-extensions mongodb

# Copy custom configuration
COPY my-config.yaml /var/www/html/user/config/system.yaml
```

## Development Setup

### With Xdebug

```yaml
services:
  grav:
    build:
      context: .
      args:
        PHP_EXTRA_EXTENSIONS: xdebug
    ports:
      - "8080:80"
    volumes:
      - ./site:/var/www/html
    environment:
      - XDEBUG_MODE=debug
      - XDEBUG_CONFIG=client_host=host.docker.internal
```

### Custom Initialization Scripts

Add scripts to `/docker-entrypoint.d/` to run before Apache starts:

```dockerfile
FROM getgrav/grav:latest
COPY my-init.sh /docker-entrypoint.d/
RUN chmod +x /docker-entrypoint.d/my-init.sh
```

## Production Deployment

### Basic Setup

```yaml
services:
  grav:
    image: getgrav/grav
    ports:
      - "80:80"
    volumes:
      - grav_data:/var/www/html
    restart: always

volumes:
  grav_data:
```

### With Traefik Reverse Proxy

```yaml
services:
  grav:
    image: getgrav/grav
    volumes:
      - grav_data:/var/www/html
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grav.rule=Host(`example.com`)"
      - "traefik.http.routers.grav.tls.certresolver=letsencrypt"
    restart: always

volumes:
  grav_data:
```

## Troubleshooting

### Checking Logs

```bash
# Container logs
docker logs <container>

# Apache error log
docker exec <container> tail -f /var/log/apache2/error.log

# Grav logs
docker exec <container> tail -f /var/www/html/logs/grav.log
```

### Grav CLI

```bash
# Clear cache
docker exec <container> bin/grav clearcache

# Install plugins
docker exec <container> bin/gpm install admin

# Check PHP info
docker exec <container> php -i
```

### Health Check

The container includes a health check that polls `http://localhost/` every 30 seconds. Check health status:

```bash
docker inspect --format='{{.State.Health.Status}}' <container>
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Links

- [Grav Documentation](https://learn.getgrav.org)
- [Grav GitHub](https://github.com/getgrav/grav)
- [Docker Hub](https://hub.docker.com/r/getgrav/grav)
- [Report Issues](https://github.com/getgrav/docker-grav/issues)
