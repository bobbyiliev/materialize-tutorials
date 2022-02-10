FROM docker.vectorized.io/vectorized/redpanda:v21.10.1

USER root

RUN apt update -y && apt install jq -y

COPY . /datagen

COPY docker-entrypoint.sh /usr/local/bin

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

USER redpanda