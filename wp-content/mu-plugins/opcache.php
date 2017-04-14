<?php
/**
 * Plugin Name: Disable Opcache
 * Description: Disables opcache in the development environment.
 * Version: 0.1
 * Author: XWP
 * Author URI: http://xwp.co
 */

if ( defined( 'WP_ENV' ) && 'dev' === WP_ENV ) {
	ini_set( 'opcache.enable', false );
}
