<?php
/**
 * Add Redis configs.
 *
 * @package WP_Docker
 */

define( 'WP_CACHE', true );

global $redis_server;
$redis_server = array(
	'host'     => 'redis',
	'port'     => 6379,
	'auth'     => 'redis',
	'database' => 0,
);
