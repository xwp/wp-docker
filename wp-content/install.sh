#!/bin/bash

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

# Checking out the default theme
echo "Checking out default theme..."
wp theme install ${WP_THEME_NAME} --allow-root

if [ ! is_active_theme ]; then
    wp theme activate ${WP_THEME_NAME} --allow-root
fi

echo
echo "Activating Plugins..."

wp plugin activate \
	query-monitor \
	wp-redis \
	--allow-root