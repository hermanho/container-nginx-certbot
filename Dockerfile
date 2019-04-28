FROM staticfloat/nginx-certbot
LABEL maintainer="Herman Ho <hmcherman@gmail.com>"

ENTRYPOINT []
CMD ["/bin/bash", "/scripts/entrypoint-herman.sh"]
