FROM php:7.1-fpm-alpine

ENV PHPREDIS_VERSION 3.1.2

RUN apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        curl \
        curl-dev \
        freetype-dev \
        icu \
        icu-dev \
        libintl \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libxml2-dev \

    && apk add --no-cache --virtual .persistent-deps \
        bash \
        grep \
        sed \
        git \
        mariadb-client \
        subversion \

    && docker-php-ext-configure gd \
        --with-png-dir=/usr \
        --with-jpeg-dir=/usr \

    && docker-php-ext-install \
        bcmath \
        curl \
        exif \
        gd \
        iconv \
        intl \
        mbstring \
        mcrypt \
        mysqli \
        opcache \
        zip \

    && { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=60'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini \

    # Install php-redis
    && curl -L -o /tmp/redis.tar.gz https://github.com/phpredis/phpredis/archive/$PHPREDIS_VERSION.tar.gz  \
    && mkdir /tmp/redis \
    && tar -xf /tmp/redis.tar.gz -C /tmp/redis \
    && rm /tmp/redis.tar.gz \
    && ( \
    cd /tmp/redis/phpredis-$PHPREDIS_VERSION \
    && phpize \
        && ./configure \
    && make -j$(nproc) \
        && make install \
    ) \
    && rm -r /tmp/redis \
    && docker-php-ext-enable redis \

    # Install xdebug
    && yes | pecl install xdebug \
    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
    && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini \

    && find /usr/local/lib/php/extensions -name '*.a' -delete \
    && find /usr/local/lib/php/extensions -name '*.so' -exec strip --strip-all '{}' \; \

    && find /usr/local \
        \( -type d -a -name test -o -name tests \) \
        -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
        -exec rm -rf '{}' + \

    && runDeps="$( \
        scanelf --needed --nobanner --recursive /usr/local \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --virtual .run-deps $runDeps \
    && apk del .build-deps \
    && rm -rf /var/lib/apk/lists/* /usr/share/doc/* /usr/share/man/* /usr/share/info/* /var/cache/apk/*

# Install wp-cli
RUN curl -o /usr/local/bin/wp -SL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli-nightly.phar \
    && chmod +x /usr/local/bin/wp

# Install PHPUnit
RUN curl https://phar.phpunit.de/phpunit-5.7.5.phar -L -o phpunit.phar \
    && chmod +x phpunit.phar \
    && mv phpunit.phar /usr/local/bin/phpunit

# Install phpcs & wpcs standard
RUN curl -o /usr/local/bin/phpcs -SL https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar \
    && chmod +x /usr/local/bin/phpcs \
    && git clone -b master --depth=1 https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards.git /usr/local/bin/wpcs \
    && /usr/local/bin/phpcs --config-set show_progress 1 \
    && /usr/local/bin/phpcs --config-set colors 1 \
    && /usr/local/bin/phpcs --config-set installed_paths /usr/local/bin/wpcs

# Install phpcbf
RUN curl -o /usr/local/bin/phpcbf -SL https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar \
    && chmod +x /usr/local/bin/phpcbf

WORKDIR /var/www/html/wordpress/

CMD ["php-fpm"]