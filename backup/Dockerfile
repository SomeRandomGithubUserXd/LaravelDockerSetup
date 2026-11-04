# base = the same mysql as our db, so mysqldump matches the server version exactly
FROM mysql:8.4
# make sure we have curl, gzip and tar
RUN microdnf install -y curl gzip tar && microdnf clean all
# rclone = one static binary that uploads to any S3
COPY --from=rclone/rclone:1 /usr/local/bin/rclone /usr/local/bin/rclone
# rclone config without secrets, keys come from env
COPY rclone.conf /root/.config/rclone/rclone.conf
COPY backup.sh /usr/local/bin/backup.sh
CMD ["bash", "/usr/local/bin/backup.sh"]