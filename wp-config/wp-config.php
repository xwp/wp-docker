<?php

foreach( glob( '/var/www/html/wp-config/*.php' ) as $config ) {
	if ( 'wp-config.php' === basename( $config ) ) {
		continue;
	}
	require( $config );
}

define( 'DB_NAME', $_ENV['WP_DB_NAME'] );
define( 'DB_USER', $_ENV['WP_DB_USER'] );
define( 'DB_PASSWORD', $_ENV['WP_DB_PASSWORD'] );
define( 'DB_HOST', $_ENV['WP_DB_HOST'] );

$table_prefix = 'wp_';

# content directory
define( 'WP_CONTENT_DIR', '/var/www/html/wp-content' );

/* That's all, stop editing! Happy blogging. */

if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', dirname( __FILE__ ) . '/' );
}

require_once( ABSPATH . 'wp-settings.php' );
