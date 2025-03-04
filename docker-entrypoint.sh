#!/bin/sh
set -e

# Create necessary directories and adjust permissions
mkdir -p /var/cache/nginx/client_temp
chmod -R 777 /var/cache/nginx
chown -R nginx:nginx /var/cache/nginx
chown -R nginx:nginx /usr/share/nginx/html

exec "$@"
