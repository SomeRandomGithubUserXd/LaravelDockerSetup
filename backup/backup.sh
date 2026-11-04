#!/bin/bash
set -o pipefail

backup() {
  set -e
  local name dump
  name=$(date +%Y-%m-%d_%H-%M)
  dump=/tmp/$name.sql.gz
  # db: consistent snapshot without locking tables
  MYSQL_PWD="$DB_ROOT_PASSWORD" mysqldump -h mysql -uroot \
    --single-transaction --routines --triggers "$DB_DATABASE" | gzip > "$dump"
  rclone copy "$dump" "s3:$S3_PATH/mysql"
  rm -f "$dump"
  # drop dumps older than 14 days (only in mysql folder)
  rclone delete "s3:$S3_PATH/mysql" --min-age 14d
  # storage/app: eternal copy, only new files are uploaded,
  # nothing is deleted or overwritten in the backup
  rclone copy /storage/app "s3:$S3_PATH/storage" --ignore-existing
  # pulse: only reached if everything above succeeded
  [ -z "$PING_URL" ] || curl -fsS -m 10 "$PING_URL" > /dev/null
  echo "backup $name ok"
}

# manual run: backup.sh now
if [ "$1" = "now" ]; then
  backup
  exit
fi

while true; do
  # sleep until next 03:00 (UTC)
  sleep $(( ($(date -d 03:00 +%s) - $(date +%s) + 86400) % 86400 ))
  ( backup ) || echo "backup FAILED"
  sleep 60
done