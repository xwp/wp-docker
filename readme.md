# WP Docker (Beta)

A docker environment for WordPress development.

## Requirements

* git
* svn
* docker
* docker-compose

## Usage

Start:

```
bin/up
```

Although it's not recommended, you can alternatively use:

```
docker-compose up
```

Stop:

```
bin/down
```

Alternatively use:

```
docker-compose down
```

## Run PHPUnit Commands

```
bin/phpunit 
```

Running the default command without any parameters will not run the unit tests. That is due to the fact the current working directory when running test in Docker is the host machines `/{project_root}/bin` directory.
 
The `bin/phpunit` file is a wrapper for `phpunit` inside Docker and excepts all the same parameters. So the following will run the unit tests for the plugins.

```
bin/phpunit -c /var/www/html/tests/phpunit.xml.dist 
```

The `pre-commit` hook will run the testsuite for the plugins automatically due to the `PHPUNIT_CONFIG` variable found in the `.dev-lib` configuration file. You can additionally add a coverage clover by doing the following. Notice that relative paths work, as well. 

```
bin/phpunit -c ../tests/phpunit.xml.dist --coverage-html ../tests/coverage
```

## Run WP-CLI Commands

1. `docker ps`
1. Get the ID of the PHP container
1. `docker exec -it <id> <command>`

## Deploying

To deploy to a public environment, define the following environment
variables in `docker-custom.yml` and run `docker-compose -f docker-compose.yml -f docker-production.yml -f docker-custom.yml up -d`.

```
php:
	environment:
		WP_DOMAIN: example.com
		WP_ADMIN_USER: me
		WP_ADMIN_EMAIL: me@example.com
```

## FAQ

#### Can I force SSL in wp-admin?

Yes! Add the following to the php section in `docker-custom.yml`

```
php:
	environment:
		FORCE_SSL_ADMIN: 1
```
