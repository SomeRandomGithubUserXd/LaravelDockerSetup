#!/bin/sh
set -e

# read value of KEY from a file (empty if missing)
get_env() { grep "^$2=" "$1" 2>/dev/null | head -n 1 | cut -d= -f2-; }

# write KEY=VALUE into a file: replace the line if it exists, append otherwise
set_env() {
  if grep -q "^$2=" "$1"; then
    awk -v k="$2" -v v="$3" 'index($0, k"=")==1 {print k"="v; next} {print}' "$1" > "$1.tmp" \
      && mv "$1.tmp" "$1"
  else
    echo "$2=$3" >> "$1"
  fi
}

# var VAR "question" "default" [gum input flags]
# filled in .env -> keep it, empty -> ask (script default) and save
var() {
  name=$1 header=$2 default=$3; shift 3
  value=$(get_env .env "$name")
  if [ -z "$value" ]; then
    value=$(gum input --header "$header" --value "$default" --placeholder "$default" "$@")
    set_env .env "$name" "$value"
  fi
  eval "$name=\$value"
}
random() { openssl rand -hex 16; }

gum style --bold --foreground 212 "Project setup"

# 1-2. env files, only if missing
# docker .env: keys from example with empty values, so the script asks every field
[ -f .env ] || sed -E 's/^([A-Za-z_][A-Za-z0-9_]*)=.*/\1=/' .env.example > .env
[ -f app/.env ] || cp app/.env.example app/.env

# 3. app key: only if empty
if [ -z "$(get_env app/.env APP_KEY)" ]; then
  KEY=$(gum input --password --header "APP_KEY" --placeholder "Enter = generate new")
  if [ -z "$KEY" ]; then
    KEY="base64:$(openssl rand -base64 32)"
    gum style --foreground 214 "New key, save it somewhere safe:" "$KEY"
  fi
  set_env app/.env APP_KEY "$KEY"
fi

# 4. docker vars
APP_ENV=$(get_env .env APP_ENV)
if [ -z "$APP_ENV" ]; then
  APP_ENV=$(gum choose --header "Environment" local staging production)
  set_env .env APP_ENV "$APP_ENV"
fi
# debug follows environment, never asked
case $APP_ENV in
  production) set_env .env APP_DEBUG false ;;
  *)          set_env .env APP_DEBUG true ;;
esac
# which compose files to use: local adds live code, vite and db ports
case $APP_ENV in
  local) set_env .env COMPOSE_FILE docker-compose.yml:docker-compose.local.yml ;;
  *)     set_env .env COMPOSE_FILE docker-compose.yml ;;
esac
var APP_UID          "File owner UID"                                  "1000"
var APP_NAME         "Project name"                                    "Laravel"
var APP_URL          "APP_URL"                                         "http://localhost"
var SITE_ADDRESS     "Caddy site address (:80 = http, domain = https)" ":80"
var HTTP_PORT        "HTTP port"                                       "80"
var HTTPS_PORT       "HTTPS port"                                      "443"
var DB_DATABASE      "Database name"                                   "app"
var DB_USERNAME      "Database user"                                   "app"
var DB_PASSWORD      "Database password"                               "$(random)"
var DB_ROOT_PASSWORD "Database root password"                          "$(random)"
var REDIS_PASSWORD   "Redis password"                                  "$(random)"

# 5. backups: on if S3_PATH is filled, otherwise offer to set up
if [ -z "$(get_env .env S3_PATH)" ] && gum confirm "Set up S3 backups?"; then
  var S3_PATH "Bucket/folder" "bucket/$APP_NAME-$APP_ENV"
  # heartbeat is optional, so asked only right when backups are set up
  set_env .env BACKUP_PING_URL "$(gum input --header "Heartbeat URL" --placeholder "Enter = no heartbeat")"
fi
if [ -n "$(get_env .env S3_PATH)" ]; then
  var S3_ACCESS_KEY "S3 access key" ""
  var S3_SECRET_KEY "S3 secret key" "" --password
  set_env .env COMPOSE_PROFILES backup
else
  set_env .env COMPOSE_PROFILES ""
fi

gum style --border rounded --padding "0 1" "Done. Run: docker compose up -d --build"