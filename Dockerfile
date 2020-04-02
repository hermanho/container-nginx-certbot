FROM nginx:alpine
LABEL maintainer="Herman Ho <hmcherman@gmail.com>"
LABEL version="1.5.5"

# Add /scripts/startup directory to source more startup scripts
RUN mkdir -p /scripts/startup
# Copy in default nginx configuration (which just forwards ACME requests to
# certbot, or redirects to HTTPS, but has no HTTPS configurations by default).
RUN rm -f /etc/nginx/conf.d/*
COPY ./nginx_conf.d/ /etc/nginx/conf.d/
COPY ./scripts/ /scripts/
RUN chmod +x /scripts/*.sh 

# RUN apt update && \
#   apt install -y libssl-dev curl certbot python3 && \
#   apt-get clean && \
#   rm -rf /var/lib/apt/lists/*

RUN apk add --no-cache --update bash grep ncurses coreutils curl certbot python3 \
  && rm -rf /var/cache/apk/* \
  && if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi \
  && rm -fr /var/cache/apk/*

ENTRYPOINT []
CMD ["/bin/bash", "/scripts/entrypoint-herman.sh"]
