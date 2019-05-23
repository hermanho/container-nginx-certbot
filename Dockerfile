FROM staticfloat/nginx-certbot
LABEL maintainer="Herman Ho <hmcherman@gmail.com>"

COPY ./scripts/ /scripts
RUN chmod +x /scripts/*.sh

RUN apt-get update && apt-get install -y libssl-dev curl

ENTRYPOINT []
CMD ["/bin/bash", "/scripts/entrypoint-herman.sh"]
