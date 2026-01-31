# Grav CMS Docker Image

Official Docker image for [Grav CMS](https://getgrav.org) - a modern, fast, flat-file CMS.

## Quick Start

```bash
docker run -d -p 8080:80 -v grav_site:/var/www/html getgrav/grav
```

Open http://localhost:8080 - Grav installs automatically on first run.

## Tags

| Tag | Description |
|-----|-------------|
| `latest`, `php8.3` | PHP 8.3 (default) |
| `php8.5` | PHP 8.5 (latest) |
| `php8.4` | PHP 8.4 |

## Docker Compose

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

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GRAV_SETUP` | `true` | Auto-install Grav if empty |
| `GRAV_CHANNEL` | `stable` | `stable` or `beta` |
| `GRAV_SCHEDULER` | `true` | Enable scheduler cron |
| `FIX_PERMISSIONS` | `false` | Fix permissions on start |

## Grav Beta

```bash
docker run -d -p 8080:80 -e GRAV_CHANNEL=beta -v grav_site:/var/www/html getgrav/grav
```

## Using Existing Site

```bash
docker run -d -p 8080:80 -v /path/to/your/grav:/var/www/html getgrav/grav
```

## Fixing Permissions

```bash
docker run -d -p 8080:80 -e FIX_PERMISSIONS=true -v ./site:/var/www/html getgrav/grav
```

## Links

- [GitHub Repository](https://github.com/getgrav/docker-grav)
- [Grav Documentation](https://learn.getgrav.org)
- [Report Issues](https://github.com/getgrav/docker-grav/issues)
