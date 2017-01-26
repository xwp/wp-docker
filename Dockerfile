FROM php:fpm

# Install memcached for PHP 7
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libmemcached-dev \
    curl \
    subversion \
    git \
    zip \
    unzip

RUN curl -L -o /tmp/memcached.tar.gz "https://github.com/php-memcached-dev/php-memcached/archive/php7.tar.gz" \
    && mkdir -p /usr/src/php/ext/memcached \
    && tar -C /usr/src/php/ext/memcached -zxvf /tmp/memcached.tar.gz --strip 1 \
    && docker-php-ext-configure memcached \
    && docker-php-ext-install memcached \
    && rm /tmp/memcached.tar.gz

# install the PHP extensions we need for WordPress
RUN apt-get update && apt-get install -y mariadb-client libpng12-dev libjpeg-dev && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd mysqli opcache

ENV WORDPRESS_VERSION 4.7.1
ENV WORDPRESS_SHA1 8e56ba56c10a3f245c616b13e46bd996f63793d6

RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
	&& echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
	&& tar -xzf wordpress.tar.gz -C /usr/src/ \
	&& rm wordpress.tar.gz \
	&& chown -R www-data:www-data /usr/src/wordpress

COPY ./php/conf.d/wordpress.ini /usr/local/etc/php/conf.d/wordpress.ini

COPY ./wp-config.php /usr/src/wordpress
VOLUME /usr/src/wordpress
WORKDIR /usr/src/wordpress

# Install wp-cli
RUN curl -o /usr/local/bin/wp -SL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli-nightly.phar \
	&& chmod +x /usr/local/bin/wp

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer

COPY ./bin/install-wp /usr/local/bin/install-wp
CMD /usr/local/bin/install-wp
