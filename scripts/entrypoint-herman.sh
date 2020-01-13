#!/bin/sh

# When we get killed, kill all our children
trap "exit" INT TERM
trap "kill 0" EXIT

if [ -z "$IS_STAGING" ]; then
    export IS_STAGING=1
fi

if [ -z "$DOMAINS" ]; then
    error "DOMAINS environment variable undefined"
    exit 1
fi

nginx -v
python3 --version
python3 scripts/create-nginx-config.py
[ $? -ne 0 ] && exit 1

. $(cd $(dirname $0); pwd)/entrypoint.sh