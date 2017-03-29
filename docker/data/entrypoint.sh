#!/bin/bash

if [ -z "$@" ]; then
    trap exit SIGTERM

    while true; do
	sleep 0.1
    done
fi

exec "$@"