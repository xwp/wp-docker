#!/bin/bash

set -e
set -v

docker login -u $DOCKER_USER -p $DOCKER_PASS
docker image build -t $DOCKER_REPO:latest -t $DOCKER_REPO:7.1-fpm-alpine ./docker/php
docker push $DOCKER_REPO
