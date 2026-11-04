# Laravel Docker Setup

Laravel + PHP-FPM (Alpine), MySQL, Redis, Caddy (auto HTTPS), queue worker, scheduler and optional S3 backups. One universal build for local, staging and production.

## Requirements

Docker with Compose v2. Works on macOS and Linux (and WSL).

## Quick start

```sh
./init.sh
docker compose up -d --build
```

`init.sh` asks a few questions and creates `.env` and `app/.env`: environment, URL, ports, passwords (random by default), `APP_KEY`, and optionally S3 backups. It runs only once. To reconfigure, delete both `.env` files and run it again.

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
```

## Useful commands

```sh
docker compose logs -f app                 # app logs
docker compose exec app php artisan ...    # artisan
docker compose exec backup bash /usr/local/bin/backup.sh now   # manual backup
```

## Notes

- `SITE_ADDRESS=:80` means plain HTTP. Set it to a domain (`example.com`) to get a Let's Encrypt certificate automatically.
- MySQL sets passwords only when its volume is created. If you change them in `.env` later, change them in MySQL too, or recreate the volume locally with `docker compose down -v` (but that drops the db).
- Backups run daily at 03:00 UTC. Dumps go to `S3_PATH/mysql` (kept 14 days), and `storage/app` is copied to `S3_PATH/storage` (new files only, nothing is ever deleted).