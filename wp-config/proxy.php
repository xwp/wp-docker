<?php
/**
 * Add proxy configs.
 *
 * @package WP_Docker
 */

$is_remote = (
	isset( $_SERVER['HTTP_X_FORWARDED_FOR'] )
	&&
	(
		filter_var( $_SERVER['HTTP_X_FORWARDED_FOR'], FILTER_VALIDATE_IP, FILTER_FLAG_IPV4 )
		||
		filter_var( $_SERVER['HTTP_X_FORWARDED_FOR'], FILTER_VALIDATE_IP, FILTER_FLAG_IPV6 )
	)
);

if ( $is_remote ) {
	$_SERVER['REMOTE_ADDR'] = $_SERVER['HTTP_X_FORWARDED_FOR'];
}

if ( isset( $_SERVER['HTTP_X_FORWARDED_HOST'] ) ) {
	$_SERVER['HTTP_HOST'] = $_SERVER['HTTP_X_FORWARDED_HOST'];
}

// Proxied request, adjust SERVER_PORT accordingly.
if ( isset( $_SERVER['HTTP_X_FORWARDED_PORT'] ) && is_numeric( $_SERVER['HTTP_X_FORWARDED_PORT'] ) ) {
	$_SERVER['SERVER_PORT'] = intval( $_SERVER['HTTP_X_FORWARDED_PORT'] );
}

if ( isset( $_SERVER['HTTP_X_FORWARDED_PROTO'] ) && 'https' === $_SERVER['HTTP_X_FORWARDED_PROTO'] ) {
	$_SERVER['HTTPS'] = 'on';
}
