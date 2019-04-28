FROM staticfloat/nginx-certbot
LABEL maintainer="Herman Ho <hmcherman@gmail.com>"

COPY ./scripts/ /scripts
RUN chmod +x /scripts/*.sh

ENTRYPOINT []
CMD ["/bin/bash", "/scripts/entrypoint-herman.sh"]
