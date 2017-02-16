<?php
define( 'WP_CONTENT_DIR', dirname( __DIR__ ) . '/../wp-content/' );
define( 'WP_PLUGIN_DIR', WP_CONTENT_DIR . 'plugins/' );

global $_plugin_files;
$_plugin_files = array();

$_tests_dir = getenv( 'WP_TESTS_DIR' );

// Travis CI tests directory.
if ( empty( $_tests_dir ) ) {
	$_tests_dir = '/tmp/wordpress-tests';
}

// Docker tests directory.
if ( ! file_exists( $_tests_dir . '/includes/' ) ) {
	$_tests_dir = '/var/www/html/wp-tests';
}

if ( ! file_exists( $_tests_dir . '/includes/' ) ) {
	trigger_error( 'Unable to locate wordpress-tests-lib', E_USER_ERROR );
}
require_once $_tests_dir . '/includes/functions.php';

foreach ( glob( getcwd() . '/../wp-content/plugins/*' ) as $_plugin_candidate ) {
	if ( is_dir( $_plugin_candidate ) && 'akismet' !== basename( $_plugin_candidate ) ) {
		foreach ( glob( $_plugin_candidate . '/*.php' ) as $_plugin_file_candidate ) {
			if ( basename( $_plugin_candidate ) !== basename( $_plugin_file_candidate, '.php' ) ) {
				continue;
			}
			// @codingStandardsIgnoreStart
			$_plugin_file_src = file_get_contents( $_plugin_file_candidate );
			// @codingStandardsIgnoreEnd
			if ( preg_match( '/Plugin\s*Name\s*:/', $_plugin_file_src ) ) {
				$_plugin_files[] = $_plugin_file_candidate;
				break;
			}
		}
	}
}

if ( empty( $_plugin_files ) ) {
	trigger_error( 'Unable to locate any files containing a plugin metadata block.', E_USER_ERROR );
}
unset( $_plugins, $_plugin_candidate, $_plugin_file_candidate, $_plugin_file_src );

function xwp_unit_test_load_plugin_file() {
	global $_plugin_files;

	// Load the plugins
	foreach ( $_plugin_files as $file ) {
		require_once $file;
	}
	unset( $_plugin_files );
}
tests_add_filter( 'muplugins_loaded', 'xwp_unit_test_load_plugin_file' );

require $_tests_dir . '/includes/bootstrap.php';
