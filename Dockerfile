FROM php:fpm

# Install redis for PHP 7
RUN apt-get update \
    && apt-get install -y \
        curl \
        libjpeg-dev \
        libmemcached-dev \
        libpng12-dev \
        libpq-dev \
        git \
        subversion \
        mariadb-client \
        zip \
        unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -L -o /tmp/redis.tar.gz "https://github.com/phpredis/phpredis/archive/3.1.1.tar.gz" \
    && mkdir -p /usr/src/php/ext/redis \
    && tar -C /usr/src/php/ext/redis -zxvf /tmp/redis.tar.gz --strip 1 \
    && docker-php-ext-configure redis \
    && docker-php-ext-configure \
        gd \
        --with-png-dir=/usr \
        --with-jpeg-dir=/usr \
    && docker-php-ext-install \
        gd \
        redis \
        mysqli \
        opcache \
    && rm /tmp/redis.tar.gz

# Install xdebug
RUN yes | pecl install xdebug \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini

# Install wp-cli
RUN curl -o /usr/local/bin/wp -SL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli-nightly.phar \
    && chmod +x /usr/local/bin/wp

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

# Install PHPUnit
RUN curl https://phar.phpunit.de/phpunit-5.7.5.phar -L -o phpunit.phar \
    && chmod +x phpunit.phar \
    && mv phpunit.phar /usr/local/bin/phpunit

# Install phpcs & wpcs standard
RUN curl -o /usr/local/bin/phpcs -SL https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar \
    && chmod +x /usr/local/bin/phpcs \
    && git clone -b master https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards.git /usr/local/bin/wpcs \
    && /usr/local/bin/phpcs --config-set show_progress 1 \
    && /usr/local/bin/phpcs --config-set colors 1 \
    && /usr/local/bin/phpcs --config-set installed_paths /usr/local/bin/wpcs

# Install phpcbf
RUN curl -o /usr/local/bin/phpcbf -SL https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar \
    && chmod +x /usr/local/bin/phpcbf

COPY ./php/conf.d/wordpress.ini /usr/local/etc/php/conf.d/wordpress.ini
WORKDIR /var/www/html/wordpress/

# Install WordPress
COPY ./bin/install-wp /usr/local/bin/install-wp
CMD /usr/local/bin/install-wp