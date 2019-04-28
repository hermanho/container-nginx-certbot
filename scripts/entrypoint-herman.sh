#!/bin/sh

# When we get killed, kill all our children
trap "exit" INT TERM
trap "kill 0" EXIT

python create-nginx-config.py
[ $? -ne 0 ] && exit 1

. entrypoint.sh