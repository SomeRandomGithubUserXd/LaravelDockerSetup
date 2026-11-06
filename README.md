# Laravel Docker Setup

Laravel + PHP-FPM (Alpine), MySQL, Redis, Caddy (auto HTTPS), queue worker, scheduler and optional S3 backups. One universal build for local, staging and production.

## Requirements

Docker with Compose v2. Works on macOS and Linux (and WSL).

## Quick start

```sh
./init.sh
docker compose up -d --build
```

`init.sh` asks a few questions and creates `.env` and `app/.env`: environment, URL, ports, passwords (random by default), `APP_KEY`, and optionally S3 backups. It's safe to run any time: it only asks for empty values and never overwrites what is already filled, so you can also fill `.env` by hand (`.env.example` lists the fields) and let the script ask for the rest. `APP_DEBUG` is set from the environment automatically (`false` for production, `true` otherwise).

## Local development

Choose `local` in `init.sh`. It adds `docker-compose.local.yml` on top of the main file (via `COMPOSE_FILE` in `.env`) and installs `vendor` and `node_modules` into `app/` on the first run. In local mode:

- code is mounted from `app/`, changes are visible without rebuilding (no `optimize`, so routes and config don't get stuck in cache);
- `vite` service runs `npm run dev` with hot reload on port 5173;
- the queue worker uses `queue:listen`, so job changes are picked up without restarts;
- MySQL and Redis are available on `127.0.0.1:3306` and `127.0.0.1:6379`.

On staging and production the code is baked into the image, so any change needs `docker compose up -d --build`.

## Updating

```sh
git pull
docker compose up -d --build
```

`php artisan optimize` runs automatically on every start.

## Structure

```
app/      Laravel + its Dockerfile
web/      Caddy: serves public/ and storage, proxies PHP to app:9000
backup/   nightly MySQL dump + storage copy to S3
setup/    interactive installer used by init.sh
docker-compose.local.yml   local-only overrides (live code, vite, db ports)
```

## Useful commands

```sh
docker compose logs -f app                 # app logs
docker compose exec app php artisan ...    # artisan
docker compose exec app composer require ...   # local mode: changes go to app/
docker compose exec vite npm install ...       # local mode
docker compose exec backup bash /usr/local/bin/backup.sh now   # manual backup
```

## Notes

- `SITE_ADDRESS=:80` means plain HTTP. Set it to a domain (`example.com`) to get a Let's Encrypt certificate automatically.
- MySQL sets passwords only when its volume is created. If you change them in `.env` later, change them in MySQL too, or recreate the volume locally with `docker compose down -v` (but that drops the db).
- Backups run daily at 03:00 UTC. Dumps go to `S3_PATH/mysql` (kept 14 days), and `storage/app` is copied to `S3_PATH/storage` (new files only, nothing is ever deleted).
- Backups are enabled when `S3_PATH` is set (`COMPOSE_PROFILES=backup` is set by `init.sh`). Set `BACKUP_PING_URL` to get alerted when a nightly backup doesn't happen.