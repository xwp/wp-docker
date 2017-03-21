#!/bin/bash

echo
echo "Activating Plugins..."

wp plugin activate \
	query-monitor \
	wp-redis \
	--allow-root