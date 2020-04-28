#!/bin/bash

set -o errexit

# When we get killed, kill all our children
trap "exit" INT TERM
trap "kill 0" EXIT

echo "entrypoint-herman"

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


if [ "$ENABLE_NAXSI" == "true" ] || [ "$ENABLE_NAXSI" == "TRUE" ]; then
    echo "ENABLE_NAXSI = $ENABLE_NAXSI"
    cat <(echo "load_module /etc/nginx/modules/ngx_http_naxsi_module.so; # load naxsi") /etc/nginx/nginx.conf >> /etc/nginx/nginx2.conf
    mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
    mv /etc/nginx/nginx2.conf /etc/nginx/nginx.conf
    mv /etc/nginx/conf.d/naxsi.conf.disable /etc/nginx/conf.d/naxsi.conf
fi

. $(cd $(dirname $0); pwd)/entrypoint.sh