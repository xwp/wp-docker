# WP Docker (Beta)

A docker environment for WordPress site development.

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

## PHPUnit

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

## MySQL

Docker will execute files with extensions `.sh`, `.sql` and `.sql.gz` that are found in the `mysql` directory. Files will be executed in alphabetical order. You can easily populate your mariadb services by [mounting a SQL dump into that directory](https://docs.docker.com/engine/tutorials/dockervolumes/#mount-a-host-file-as-a-data-volume) and provide [custom images](https://docs.docker.com/reference/builder/) with contributed data. SQL files will be imported by default to the database specified by the `MYSQL_DATABASE` variable. However, it may not be the ideal workflow to load the DB this way so there are additional custom import and export capabilities.

Import:

```
bin/mysql-import {path-to-sql-file} 
```

Running the `bin/mysql-import` bash script will import an SQL file into the database which is defined in the `MYSQL_DATABASE` environment variable. All you need to do is supply a path to the SQL file.

Export:

```
bin/mysql-export 
```

Running the `bin/mysql-export` bash script will create a backup of the database inside the `mysql/backups` directory with the format `{db-name}-{timestamp}.sql`

## Run WP-CLI Commands

1. `docker ps`
1. Get the ID of the PHP container
1. `docker exec -it <id> <command>`

Alternatively you can use `docker-compose`

1. `docker-compose run --rm php <command>`

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
