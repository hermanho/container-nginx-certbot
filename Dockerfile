FROM nginx:alpine as nginx-naxsi-build

ARG NAXSI_VER=0.56
ENV NAXSI_VER=$NAXSI_VER

RUN apk add --no-cache --virtual .build-deps \
  gcc \
  libc-dev \
  make \
  pcre-dev \
  zlib-dev \
  linux-headers \
  gnupg \
  openssl-dev \
  curl

RUN naxsi_gpg_keys=251A28DE2685AED4 \
    ; \
    curl -fSL https://github.com/nbs-system/naxsi/archive/$NAXSI_VER.tar.gz -o naxsi_$NAXSI_VER.tar.gz \
    ; \
    curl -fSL https://github.com/nbs-system/naxsi/releases/download/$NAXSI_VER/naxsi-$NAXSI_VER.tar.gz.asc -o naxsi_$NAXSI_VER.tar.gz.asc \
    ; \
    gpg --recv-keys $naxsi_gpg_keys \
    ; \
    gpg --verify naxsi_$NAXSI_VER.tar.gz.asc naxsi_$NAXSI_VER.tar.gz \
    ; \
    rm naxsi_$NAXSI_VER.tar.gz.asc

RUN nginx_gpg_keys=520A9993A1C052F8; \
    curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx-$NGINX_VERSION.tar.gz \
    ; \
    curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc -o nginx-$NGINX_VERSION.tar.gz.asc \
    ; \
    gpg --recv-keys $nginx_gpg_keys \
    ; \
    gpg --verify nginx-$NGINX_VERSION.tar.gz.asc nginx-$NGINX_VERSION.tar.gz \
    ; \
    rm nginx-$NGINX_VERSION.tar.gz.asc

RUN mkdir -p /src ; \
    tar -vxC /src -f naxsi_$NAXSI_VER.tar.gz ; \
    tar -vxC /src -f nginx-$NGINX_VERSION.tar.gz ; \
    cd /src/nginx-$NGINX_VERSION ; \
    CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') && \
    CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p' | sed "s/--with-cc-opt='/--with-cc-opt='-Wno-stringop-truncation -Wno-stringop-overflow -Wno-size-of-pointer-memaccess /") && \
    echo "./configure --with-compat $CONFARGS --add-dynamic-module=../naxsi-$NAXSI_VER/naxsi_src" | sh ; \
    make modules

FROM nginx:alpine as final
LABEL maintainer="Herman Ho <hmcherman@gmail.com>"
LABEL version="1.6.2"

ARG NAXSI_VER=0.56
ENV NAXSI_VER=$NAXSI_VER

RUN apk add --no-cache --update bash grep ncurses coreutils curl certbot python3 \
  && rm -rf /var/cache/apk/* \
  && if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi \
  && rm -fr /var/cache/apk/*

COPY --from=nginx-naxsi-build /src/nginx-$NGINX_VERSION/objs/ngx_http_naxsi_module.so /etc/nginx/modules/
COPY --from=nginx-naxsi-build /src/naxsi-$NAXSI_VER/naxsi_config/naxsi_core.rules /etc/nginx/rules/

# Add /scripts/startup directory to source more startup scripts
RUN mkdir -p /scripts/startup
# Copy in default nginx configuration (which just forwards ACME requests to
# certbot, or redirects to HTTPS, but has no HTTPS configurations by default).
RUN rm -f /etc/nginx/conf.d/*
COPY ./nginx_customize.d/ /etc/nginx/rules/
COPY ./nginx_conf.d/ /etc/nginx/conf.d/
COPY ./scripts/ /scripts/
RUN chmod +x /scripts/*.sh 

# RUN apt update && \
#   apt install -y libssl-dev curl certbot python3 && \
#   apt-get clean && \
#   rm -rf /var/lib/apt/lists/*

HEALTHCHECK --interval=5m --timeout=5s CMD curl --fail http://127.0.0.1/nginx-health || exit 1

ENTRYPOINT []
CMD ["/bin/bash", "/scripts/entrypoint-herman.sh"]
