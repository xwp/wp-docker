#!/bin/bash

USAGE="[--help|-h] [--with-tests|-t] [--deploy|-d]"

## Process cli params
for p in "$@";
do
    case $p in
    --help|-h)
        echo "Usage: $0 ${USAGE}"
        exit 2;
        ;;
    --with-tests|-t)
        TASK="tests"
        ;;
    --deploy|-d)
        TASK="deploy"
        ;;
    *)
        echo "Invalid parameter ${p}"
        echo "Usage: $0 ${USAGE}"
        exit 2;
        ;;
    esac
done

export WP_CORE_DIR="/var/www/html/wordpress"
export WP_CONTENT_DIR="/var/www/html/wp-content"
export WP_TESTS_DIR="/var/www/html/wp-tests"

# allow any of these "Authentication Unique Keys and Salts." to be specified via
# environment variables with a "WP_" prefix (ie, "WP_AUTH_KEY")
uniqueEnvs=(
    AUTH_KEY
    SECURE_AUTH_KEY
    LOGGED_IN_KEY
    NONCE_KEY
    AUTH_SALT
    SECURE_AUTH_SALT
    LOGGED_IN_SALT
    NONCE_SALT
)
envs=(
    MYSQL_DATABASE
    MYSQL_USER
    MYSQL_PASSWORD
    WP_DB_HOST
    WP_DB_USER
    WP_DB_PASSWORD
    WP_DB_NAME
    WP_TABLE_PREFIX
    WP_DEBUG
    WP_DOMAIN
    WP_TITLE
    WP_ADMIN_USER
    WP_ADMIN_PASSWORD
    WP_ADMIN_EMAIL
    WP_VERSION
    "${uniqueEnvs[@]/#/WP_}"
)

function is_active_theme() {
    RESULT=`wp theme list \
        --status=active \
        --fields=name \
        --format=csv \
        --allow-root \
        --path=${WP_CORE_DIR} \
        | tail -1 \
        2>/dev/null`

    if [ "$RESULT" != "${WP_THEME_NAME}" ]; then
        return 0
    else
        return 1
    fi
}

function is_db_up() {
    RESULT=`mysql \
        -h ${WP_DB_HOST%:*} \
        -P${WP_DB_HOST#*:} \
        -u ${WP_DB_USER} \
        -p${WP_DB_PASSWORD} \
        --skip-column-names \
        -e "SHOW DATABASES LIKE '${WP_DB_NAME}'" \
        2>/dev/null`

    if [ "$RESULT" == "${WP_DB_NAME}" ]; then
        return 0
    else
        return 1
    fi
}

until is_db_up; do
   echo "Waiting for database to become available..."
   sleep 5
done

echo "Database is available. Continuing..."

# Download WordPress
if [ ! -e wp-config.php ] || [ ${WP_VERSION} != $(wp core version --allow-root --path=${WP_CORE_DIR}) ]; then
    wp core download \
        --allow-root \
        --path=${WP_CORE_DIR} \
        --version="${WP_VERSION}" \
        --force
fi

# Build config
echo
echo "Setup wp-config.php..."

# version 4.4.1 decided to switch to windows line endings, that breaks our seds and awks
# https://github.com/docker-library/wordpress/issues/116
# https://github.com/WordPress/WordPress/commit/1acedc542fba2482bab88ec70d4bea4b997a92e4
sed -ri -e 's/\r$//' wp-config*

if [ ! -e wp-config.php ]; then
    awk '/^\/\*.*stop editing.*\*\/$/ && c == 0 { c = 1; system("cat") } { print }' wp-config-sample.php > wp-config.php <<'EOPHP'
// Load the config files.
foreach ( glob( '/var/www/html/wp-config/*.php' ) as $config ) {
	require( $config );
}

// Set the content directory.
define( 'WP_CONTENT_DIR', "/var/www/html/wp-content" );

EOPHP
    chown www-data:www-data wp-config.php
fi

# see http://stackoverflow.com/a/2705678/433558
sed_escape_lhs() {
    echo "$@" | sed -e 's/[]\/$*.^|[]/\\&/g'
}
sed_escape_rhs() {
    echo "$@" | sed -e 's/[\/&]/\\&/g'
}
php_escape() {
    php -r 'var_export(('$2') $argv[1]);' -- "$1"
}
set_config() {
    key="$1"
    value="$2"
    var_type="${3:-string}"
    start="(['\"])$(sed_escape_lhs "$key")\2\s*,"
    end="\);"
    if [ "${key:0:1}" = '$' ]; then
        start="^(\s*)$(sed_escape_lhs "$key")\s*="
        end=";"
    fi
    sed -ri -e "s/($start\s*).*($end)$/\1$(sed_escape_rhs "$(php_escape "$value" "$var_type")")\3/" wp-config.php
}

set_config 'DB_HOST' "${WP_DB_HOST}"
set_config 'DB_USER' "${WP_DB_USER}"
set_config 'DB_PASSWORD' "${WP_DB_PASSWORD}"
set_config 'DB_NAME' "${WP_DB_NAME}"

for unique in "${uniqueEnvs[@]}"; do
    uniqVar="WP_$unique"
    if [ -n "${!uniqVar}" ]; then
        set_config "$unique" "${!uniqVar}"
    else
        # if not specified, let's generate a random value
        currentVal="$(sed -rn -e "s/define\((([\'\"])$unique\2\s*,\s*)(['\"])(.*)\3\);/\4/p" wp-config.php)"
        if [ "$currentVal" = 'put your unique phrase here' ]; then
            set_config "$unique" "$(head -c1m /dev/urandom | sha1sum | cut -d' ' -f1)"
        fi
    fi
done

if [ "$WP_TABLE_PREFIX" ]; then
    set_config '$table_prefix' "$WP_TABLE_PREFIX"
fi

if [ "$WP_DEBUG" ]; then
    set_config 'WP_DEBUG' 1 boolean
fi

if [ "$WP_ENV" ]; then
    awk '/^\/\*.*stop editing.*\*\/$/ && c == 0 { c = 1; system("cat") } { print }' wp-config.php > wp-config.tmp <<'EOPHP'
// Set the environment.
define( 'WP_ENV', getenv('WP_ENV') );
EOPHP
    mv wp-config.tmp wp-config.php
fi

# Install Core
if ! $(wp core is-installed --allow-root --path=${WP_CORE_DIR}); then
    echo
    echo "Installing WordPress..."
    wp core install \
        --allow-root \
        --path=${WP_CORE_DIR} \
        --url=${WP_DOMAIN} \
        --title="${WP_TITLE}" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --skip-email
fi

# Download Jetpack
if [ ! -e $WP_CONTENT_DIR/plugins/jetpack ]; then
	echo "Cloning Jetpack..."
	# TODO verify this stuff:
	git config --global http.sslverify "false"
	git clone --depth 1 https://github.com/Automattic/jetpack $WP_CONTENT_DIR/plugins/jetpack
fi

if [ "${TASK}" == "tests" ]; then

    # Generate the tests SVN tag
    if [[ ${WP_VERSION} =~ [0-9]+\.[0-9]+(\.[0-9]+)? ]]; then
        WP_TESTS_TAG="tags/${WP_VERSION}"
    elif [[ ${WP_VERSION} == 'nightly' || ${WP_VERSION} == 'trunk' ]]; then
        WP_TESTS_TAG="trunk"
    else
        # http serves a single offer, whereas https serves multiple. we only want one
        download http://api.wordpress.org/core/version-check/1.7/ /tmp/wp-latest.json
        grep '[0-9]+\.[0-9]+(\.[0-9]+)?' /tmp/wp-latest.json
        LATEST_VERSION=$(grep -o '"version":"[^"]*' /tmp/wp-latest.json | sed 's/"version":"//')
        if [[ -z "$LATEST_VERSION" ]]; then
            echo "Latest WordPress version could not be found"
            exit 1
        fi
        WP_TESTS_TAG="tags/$LATEST_VERSION"
    fi

    # Set up testing suite if it doesn't yet exist
    echo
    if [ ! -d $WP_TESTS_DIR ]; then
        echo "Creating WordPress Test Suite Directory..."

        # set up testing suite
        mkdir -p $WP_TESTS_DIR
    fi

    echo "Updating WordPress Test Suite..."

    svn co https://develop.svn.wordpress.org/${WP_TESTS_TAG}/tests/phpunit/includes/ $WP_TESTS_DIR/includes --trust-server-cert
    svn co https://develop.svn.wordpress.org/${WP_TESTS_TAG}/tests/phpunit/data/ $WP_TESTS_DIR/data --trust-server-cert
fi

# Ensure the plugin and theme directories exist
mkdir -p ${WP_CONTENT_DIR}/themes
mkdir -p ${WP_CONTENT_DIR}/plugins

# Checking out the default theme
echo "Checking out default theme..."
wp theme install ${WP_THEME_NAME} --allow-root --force

if [ ! is_active_theme ]; then
    wp theme activate ${WP_THEME_NAME} --allow-root
fi

echo
echo "Activating Plugins..."

wp plugin activate \
	opcache \
	query-monitor \
	wp-redis \
  jetpack
	--allow-root

echo
echo "Done!"

echo
grep "${WP_DOMAIN}" /etc/hosts > /dev/null || echo "Be sure to add '127.0.0.1 ${WP_DOMAIN}' to your /etc/hosts file"

# Let's clear out the relevant environment variables (so that stray "phpinfo()" calls don't leak secrets from our code)
for e in "${envs[@]}"; do
    if [[ "XDEBUG_CONFIG|PHP_IDE_CONFIG|WP_ENV" =~ "$e" ]]; then
        continue
    fi
	unset "$e"
done

php-fpm -F
