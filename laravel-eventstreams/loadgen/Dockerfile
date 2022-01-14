FROM ubuntu:latest

RUN apt-get update && apt-get -qy install curl

COPY . /trades

COPY docker-entrypoint.sh /usr/local/bin
RUN chmod 777 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]