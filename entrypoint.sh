#!/bin/bash
set -euo pipefail

if [[ "$1" == apache2* ]] || [ "$1" == php-fpm ]; then
	if [ "$(id -u)" = '0' ]; then
		case "$1" in
			apache2*)
				user="${APACHE_RUN_USER:-www-data}"
				group="${APACHE_RUN_GROUP:-www-data}"
				;;
			*) # php-fpm
				user='www-data'
				group='www-data'
				;;
		esac
	else
		user="$(id -u)"
		group="$(id -g)"
	fi

	if [ ! -e index.php ]; then
		echo >&2 "Grav not found in $PWD - copying now..."
		if [ "$(ls -A)" ]; then
			echo >&2 "WARNING: $PWD is not empty - press Ctrl+C now if this is an error!"
			( set -x; ls -A; sleep 10 )
		fi
		tar --create \
			--file - \
			--one-file-system \
			--directory /usr/src/grav-admin \
			--owner "$user" --group "$group" \
			. | tar --extract --file -
		echo >&2 "Complete! Grav has been successfully copied to $PWD"
	fi
fi
exec "$@"

