#!/bin/bash

# When we get killed, kill all our children
trap "exit" INT TERM
trap "kill 0" EXIT

if [ -z "$SLEEP_TIMEOUT" ]; then
    SLEEP_TIMEOUT=15
fi
echo "Sleep $SLEEP_TIMEOUT seconds."
# Ensure nginx bootup first
curl_ret=0
sleep $SLEEP_TIMEOUT
curl --write-out "curl http://127.0.0.1 : %{http_code}\n" --silent --output /dev/null --head --max-time 15 "http://127.0.0.1"
curl_ret=$?
if [ $curl_ret -ne 0 ]; then
    echo "$curl_ret"
    error "Nginx booting error."
    exit_code=1
    exit $exit_code
fi
echo "Nginx ready."
exit 0
# apt-get remove --purge -y libssl-dev curl && \
# apt-get autoremove -y 
# apt-get clean && \
# rm -rf /var/lib/apt/lists/*
