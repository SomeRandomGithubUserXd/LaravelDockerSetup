#!/bin/sh
set -e
docker build -q -t project-setup ./setup > /dev/null
docker run --rm -it \
  -v "$PWD":/project \
  -u "$(id -u):$(id -g)" \
  project-setup
# local: live code needs vendor and node_modules in the project folder
if grep -q '^APP_ENV=local' .env && [ ! -d app/vendor ]; then
  docker compose run --rm vite sh -c "composer install && npm ci && php artisan storage:link"
fi