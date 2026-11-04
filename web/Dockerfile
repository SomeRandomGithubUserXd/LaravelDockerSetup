FROM caddy:2-alpine
COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=app /var/www/html/public /var/www/html/public
