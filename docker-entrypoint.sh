#!/bin/sh

# Запускаем скрипт для загрузки версий
/app/apply-versions.sh

# Запускаем nginx на переднем плане
exec nginx -g 'daemon off;' 