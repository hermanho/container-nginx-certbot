FROM staticfloat/nginx-certbot AS base
LABEL maintainer="Herman Ho <hmcherman@gmail.com>"
LABEL version="1.5.0"

RUN sed -i 's|^deb http://deb.debian.org/debian|deb http://debian-archive.trafficmanager.net/debian|' /etc/apt/sources.list

FROM base
COPY ./scripts/ /scripts
RUN chmod og-w /scripts/**/*.sh
RUN chmod +x /scripts/*.sh
RUN chmod +x /scripts/**/*.sh

RUN apt-get remove --purge -y python python-dev
RUN apt-get update && \
    apt-get install -y python3 python3-distutils libssl-dev curl certbot && \
    apt-get upgrade -y && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN chown -R nginx:app /scripts
RUN chmod 755 /scripts
USER nginx

ENTRYPOINT []
CMD ["/bin/bash", "/scripts/entrypoint-herman.sh"]
