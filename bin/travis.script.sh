#!/bin/bash

set -e

while IFS= read -r line
do
    export $(echo -e "$line" | sed -e 's/[[:space:]]*$//')
done < <(docker-compose run --rm php env | grep WP_)

docker-compose run --rm php /usr/local/bin/install-wp

function is_db_up() {
    RESULT=`mysql \
        -h ${WP_DB_HOST%:*} \
        -P${WP_DB_HOST#*:} \
        -u ${WP_DB_USER} \
        -p${WP_DB_PASSWORD} \
        --skip-column-names \
        -e "SHOW DATABASES LIKE '${WP_DB_NAME}'" \
        2>/dev/null`

    if [ "$RESULT" == "${WP_DB_NAME}" ]; then
        return 0
    else
        return 1
    fi
}

until is_db_up; do
   echo "Waiting for database to become available..."
   sleep 5
done

echo "Database is available. Continuing..."
