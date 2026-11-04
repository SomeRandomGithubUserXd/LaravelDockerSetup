#!/bin/sh
set -e

# write KEY=VALUE into a file: replace the line if it exists, append otherwise
set_env() {
  if grep -q "^$2=" "$1"; then
    awk -v k="$2" -v v="$3" 'index($0, k"=")==1 {print k"="v; next} {print}' "$1" > "$1.tmp" \
      && mv "$1.tmp" "$1"
  else
    echo "$2=$3" >> "$1"
  fi
}
ask()    { gum input --header "$1" --value "$2" --placeholder "$2"; }
random() { openssl rand -hex 16; }

gum style --bold --foreground 212 "Project setup"

# 1-2. env files from examples
cp .env.example .env
cp app/.env.example app/.env

# 3. app key: paste the old one or leave empty to generate
KEY=$(gum input --password --header "APP_KEY" --placeholder "Enter = generate new")
if [ -z "$KEY" ]; then
  KEY="base64:$(openssl rand -base64 32)"
  gum style --foreground 214 "New key, save it somewhere safe:" "$KEY"
fi
set_env app/.env APP_KEY "$KEY"

# 4. docker vars
APP_ENV=$(gum choose --header "Environment" local staging production)
case $APP_ENV in
  production) APP_DEBUG=false ;;
  *)          APP_DEBUG=true ;;
esac
APP_UID=$(ask "File owner UID" "1000")
APP_NAME=$(ask "Project name" "Laravel")
APP_URL=$(ask "APP_URL" "http://localhost")
SITE_ADDRESS=$(ask "Caddy site address (:80 = http, domain = https)" ":80")
HTTP_PORT=$(ask "HTTP port" "80")
HTTPS_PORT=$(ask "HTTPS port" "443")
DB_DATABASE=$(ask "Database name" "app")
DB_USERNAME=$(ask "Database user" "app")
DB_PASSWORD=$(ask "Database password" "$(random)")
DB_ROOT_PASSWORD=$(ask "Database root password" "$(random)")
REDIS_PASSWORD=$(ask "Redis password" "$(random)")

# 5. backups: optional, service starts only with profile "backup"
S3_PATH="" S3_ACCESS_KEY="" S3_SECRET_KEY="" BACKUP_PING_URL="" COMPOSE_PROFILES=""
if gum confirm "Set up S3 backups?"; then
  S3_PATH=$(ask "Bucket/folder" "bucket/$APP_NAME-$APP_ENV")
  S3_ACCESS_KEY=$(gum input --header "S3 access key")
  S3_SECRET_KEY=$(gum input --password --header "S3 secret key")
  BACKUP_PING_URL=$(gum input --header "Heartbeat URL" --placeholder "Enter = no heartbeat")
  COMPOSE_PROFILES=backup
fi

for var in APP_UID APP_NAME APP_ENV APP_DEBUG APP_URL SITE_ADDRESS HTTP_PORT HTTPS_PORT \
           DB_DATABASE DB_USERNAME DB_PASSWORD DB_ROOT_PASSWORD REDIS_PASSWORD \
           S3_PATH S3_ACCESS_KEY S3_SECRET_KEY BACKUP_PING_URL COMPOSE_PROFILES; do
  eval "value=\$$var"
  set_env .env "$var" "$value"
done

gum style --border rounded --padding "0 1" "Done. Run: docker compose up -d --build"