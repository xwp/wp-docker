<?php

define( 'DISALLOW_FILE_EDIT', true );

if ( $_ENV['FORCE_SSL_ADMIN'] ) {
	define( 'FORCE_SSL_ADMIN', true );
}
