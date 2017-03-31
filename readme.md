# WP Docker (Beta)

[![Build Status](https://travis-ci.org/xwp/wp-docker.svg?branch=master)](https://travis-ci.org/xwp/wp-docker) [![Coverage Status](https://coveralls.io/repos/github/xwp/wp-docker/badge.svg?branch=master)](https://coveralls.io/github/xwp/wp-docker?branch=master)

A docker environment for WordPress site development.

## Requirements

* docker-compose
* composer
* npm

## Usage

Clone Repository:

```
git clone --recursive git@github.com:xwp/wp-docker.git
```

Install Plugins:

```
composer install
```

Add Environment Variables:

```
cp .env.sample .env
```
This creates a new `.env` file from the `.env.sample` file and is not checked into `git`, change the settings as needed.

Start:

```
bin/up {optional:parameters}
```

The optional parameters give you the ability to append configurations to the script. However, the `bin/up` script by default adds the `--build` parameter if nothing is passed to it. For example, you could run Docker in daemon mode by adding `-d` and that would be the only parameter. So if you want the default behaviour plus daemon mode you would do:

```
bin/up --build -d
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

## MySQL

Docker will execute files with extensions `.sh`, `.sql` and `.sql.gz` that are found in the `mysql` directory. Files will be executed in alphabetical order. You can easily populate your mariadb service by [mounting a SQL dump into that directory](https://docs.docker.com/engine/tutorials/dockervolumes/#mount-a-host-file-as-a-data-volume) and provide [custom images](https://docs.docker.com/reference/builder/) with contributed data. SQL files will be imported by default to the database specified by the `MYSQL_DATABASE` variable. However, it may not be the ideal workflow to load the DB this way so there are additional custom import and export capabilities.

Import:

```
bin/mysql-import {path-to-file}.sql
```

Running the `bin/mysql-import` bash script will import an SQL file into the database which is defined in the `MYSQL_DATABASE` environment variable. All you need to do is supply a path to the SQL file.

Export:

```
bin/mysql-export 
```

Running the `bin/mysql-export` bash script will create a backup of the database inside the `mysql/backups` directory with the format `{db-name}-{timestamp}.sql`

## PHPUnit

```
bin/phpunit 
```

Running the default command without any parameters will automatically run the testsuite. As well, the `pre-commit` hook will also run the testsuite for the plugins automatically. Both use the `PHPUNIT_CONFIG` variable found in the `.dev-lib` configuration file. 
 
The `bin/phpunit` bash script is a wrapper for `phpunit` inside Docker and excepts all the [same parameters](https://phpunit.de/manual/current/en/textui.html). The following will manually run the unit tests for the plugins.

```
bin/phpunit -c /var/www/html/wp-tests/phpunit.xml.dist 
```

You can additionally add a coverage clover by doing the following. 

```
bin/phpunit -c ../wp-tests/phpunit.xml.dist --coverage-html ../wp-tests/coverage
```

Notice that relative paths work, as well. This is because the current working directory when running test in Docker is the host machines `{project_root}/bin` directory.

## PHPCS

```
bin/phpcs {path}
```

Performs preset PHP Coding Standard and WordPress sniffs. The `bin/phpcs` bash script is a wrapper for `phpcs` inside Docker with the parameters already supplied. The script requires/accepts an absolute (docker) or relative (host) path to a directory or file. Configurations are automatically set by parameters in the `.dev-lib` file. 

## PHPCBF

```
bin/phpcbf {path}
```

To automatically fix as many sniff violations as possible, use the `phpcbf` command in place of the `phpcs` command. The `bin/phpcbf` bash script is a wrapper for `phpcbf` inside Docker with the parameters already supplied. The script requires/accepts an absolute (docker) or relative (host) path to a directory or file. Configurations are automatically set by parameters in the `.dev-lib` file. 


## Run Commands

```
bin/run {command}
```

The `bin/run` bash script is a wrapper for the following `docker-compose` script. This is essential to interacting with the `php` service and its linked services. You can quicky run commands even when the Docker container is not `up`.

1. `docker-compose run --rm php <command>`

You could also do this manually with `docker exec` by doing the following.

1. `docker ps`
1. Get the ID of the PHP container
1. `docker exec -it <id> <command>`

## Plugin Scaffolding

Foo Bar is a built-in template plugin for scaffolding WordPress plugins. The [`bin/plugin`](bin/plugin) bash script will copy the `foo-bar` plugin and make the necessary replacements via:

```bash
bin/plugin "Hello World"
```

This will create a plugin `hello-world` in the `wp-content/plugins` directory and will greatly speed up plugin development inside this repo.

Be sure to add your new plugin to the `testsuite` inside the [`wp-tests/phpunit.xml.dist`](wp-tests/phpunit.xml.dist) file to ensure your PHPUnit tests are included in the `pre-commit` hook and `bin/phpunit` script. It is required that you run this script from this repositories root directory.
