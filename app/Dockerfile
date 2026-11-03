# running from image with alpine with fpm
FROM php:8.5-fpm-alpine

# system packages: timezones, node & npm
RUN apk add --no-cache tzdata nodejs npm

# php exts
COPY --from=mlocati/php-extension-installer:2 /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions pdo_mysql redis intl zip gd pcntl

# composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# setting workdir in our virtual linux system
WORKDIR /var/www/html

# php deps: copy manifests first, so this layer is cached until they change
COPY composer.json composer.lock ./
RUN composer install --no-scripts --no-autoloader --prefer-dist

# js deps: same trick, cached separately from composer
COPY package.json package-lock.json ./
RUN npm ci

# copying the whole project (except .dockerignore)
COPY . .

# finishing: autoloader + laravel scripts, frontend build, public/storage link
RUN composer dump-autoload --optimize \
 && npm run build \
 && php artisan storage:link

# storage & cache are the only places php may write to
ARG APP_UID
RUN apk add --no-cache shadow \
 && usermod  -o -u ${APP_UID} www-data \
 && groupmod -o -g ${APP_UID} www-data

RUN chown -R www-data:www-data storage bootstrap/cache

# from here everything runs as www-data, not root
USER www-data

# ===== on container start =====
# replaces parent CMD ["php-fpm"], so we start fpm ourselves at the end
CMD php artisan optimize \
 && exec php-fpm
