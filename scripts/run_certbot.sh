#!/bin/sh

# Source in util.sh so we can have our nice tools
. $(cd $(dirname $0); pwd)/util.sh

# We require an email to register the ssl certificate for
if [ -z "$CERTBOT_EMAIL" ]; then
    error "CERTBOT_EMAIL environment variable undefined; certbot will do nothing"
    exit 1
fi

exit_code=0

# Ensure nginx bootup first
curl_ret=0
sleep 15
curl --write-out "%{http_code}\n" --silent --output /dev/null --head --max-time 15 "http://127.0.0.1"
curl_ret=$?
if [ $curl_ret -ne 0 ]
then
    echo "$curl_ret"
    error "Nginx booting error."
    exit_code=1
    exit $exit_code
fi
echo "Nginx ready."

# apt-get remove --purge -y libssl-dev curl && \
# apt-get autoremove -y 
# apt-get clean && \
# rm -rf /var/lib/apt/lists/*

set -x
# Loop over every domain we can find
for domain in $(parse_domains); do
    if is_renewal_required $domain; then
        # Renewal required for this doman.
        # Last one happened over a week ago (or never)
        if ! get_certificate $domain $CERTBOT_EMAIL; then
            error "Cerbot failed for $domain. Check the logs for details."
            exit_code=1
        fi
    else
        echo "Not run certbot for $domain; last renewal happened just recently."
    fi
done

# After trying to get all our certificates, auto enable any configs that we
# did indeed get certificates for
auto_enable_configs

# Finally, tell nginx to reload the configs
# kill -HUP $NGINX_PID
nginx -s reload
    
set +x
exit $exit_code
