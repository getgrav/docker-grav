#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
GRAV_HOME="/var/www/html"
GRAV_VERSION="${GRAV_VERSION:-latest}"
GRAV_CHANNEL="${GRAV_CHANNEL:-stable}"

# Function to install Grav
install_grav() {
    local download_url="https://getgrav.org/download/core/grav-admin"

    if [ "${GRAV_VERSION}" = "latest" ]; then
        if [ "${GRAV_CHANNEL}" = "beta" ]; then
            log_info "Installing Grav CMS (latest beta)..."
            download_url="${download_url}/latest?beta"
        else
            log_info "Installing Grav CMS (latest stable)..."
            download_url="${download_url}/latest"
        fi
    else
        log_info "Installing Grav CMS (version: ${GRAV_VERSION})..."
        download_url="${download_url}/${GRAV_VERSION}"
    fi

    cd /tmp

    # Download Grav
    curl -fsSL -o grav-admin.zip "${download_url}"

    # Extract to web root
    unzip -q grav-admin.zip

    # Move files (handle both empty and non-empty directories)
    if [ -d "${GRAV_HOME}" ] && [ "$(ls -A ${GRAV_HOME})" ]; then
        # Directory has files, merge carefully
        cp -rn /tmp/grav-admin/* "${GRAV_HOME}/" 2>/dev/null || true
        cp -rn /tmp/grav-admin/.[!.]* "${GRAV_HOME}/" 2>/dev/null || true
    else
        # Directory is empty or doesn't exist
        mkdir -p "${GRAV_HOME}"
        mv /tmp/grav-admin/* "${GRAV_HOME}/"
        mv /tmp/grav-admin/.[!.]* "${GRAV_HOME}/" 2>/dev/null || true
    fi

    # Cleanup
    rm -rf /tmp/grav-admin /tmp/grav-admin.zip

    log_info "Grav installation complete!"
}

# Function to check if Grav is installed
is_grav_installed() {
    [ -f "${GRAV_HOME}/index.php" ] && [ -f "${GRAV_HOME}/system/defines.php" ]
}

# Function to fix permissions
fix_permissions() {
    log_info "Setting permissions..."

    # Ensure www-data owns the web root
    chown -R www-data:www-data "${GRAV_HOME}"

    # Set directory permissions
    find "${GRAV_HOME}" -type d -exec chmod 755 {} \;

    # Set file permissions
    find "${GRAV_HOME}" -type f -exec chmod 644 {} \;

    # Make bin scripts executable
    if [ -d "${GRAV_HOME}/bin" ]; then
        chmod +x "${GRAV_HOME}/bin/"*
    fi

    log_info "Permissions set!"
}

# Function to setup cron
setup_cron() {
    log_info "Setting up Grav scheduler cron job..."

    # Create cron job for Grav scheduler
    CRON_JOB="* * * * * cd ${GRAV_HOME} && /usr/local/bin/php bin/grav scheduler 1>> /dev/null 2>&1"

    # Add to www-data's crontab if not already present
    (crontab -u www-data -l 2>/dev/null | grep -v "grav scheduler"; echo "${CRON_JOB}") | crontab -u www-data -

    log_info "Cron job configured!"
}

# Main entrypoint logic
main() {
    log_info "Starting Grav Docker container..."
    log_info "PHP Version: $(php -v | head -n 1)"

    # Check if Grav needs to be installed
    if ! is_grav_installed; then
        if [ "${GRAV_SETUP:-true}" = "true" ]; then
            install_grav
            fix_permissions
        else
            log_warn "Grav not installed and GRAV_SETUP=false. Skipping installation."
            log_warn "Mount your existing Grav installation to ${GRAV_HOME}"
        fi
    else
        log_info "Existing Grav installation detected. Skipping installation."

        # Still fix permissions if requested
        if [ "${FIX_PERMISSIONS:-false}" = "true" ]; then
            fix_permissions
        fi
    fi

    # Setup cron for Grav scheduler
    if [ "${GRAV_SCHEDULER:-true}" = "true" ]; then
        setup_cron
        # Start cron daemon
        service cron start
    fi

    # Run any custom initialization scripts
    if [ -d "/docker-entrypoint.d" ]; then
        for f in /docker-entrypoint.d/*.sh; do
            if [ -x "$f" ]; then
                log_info "Running custom script: $f"
                "$f"
            fi
        done
    fi

    log_info "Container initialization complete!"
    log_info "Starting Apache..."

    # Execute the main command (apache2-foreground)
    exec "$@"
}

# Run main function with all arguments
main "$@"
