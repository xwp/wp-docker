<?php
/**
 * Plugin Name: OPcache Disable
 * Description: Disables OPcache if the WordPress environment variable (WP_ENV) is set to `dev`.
 * Version: 0.1
 * Author: XWP
 * Author URI: http://xwp.co
 */

if ( defined( 'WP_ENV' ) && 'dev' === WP_ENV ) {
	ini_set( 'opcache.enable', false );
}
