#!/bin/sh

# Run version download script
/etc/nginx/apply-versions.sh

# Start nginx
exec nginx -g 'daemon off;' 