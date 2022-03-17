# MySQL -> Airbyte -> Kafka -> Materialize -> Live dashboard

For Mac M1 make sure to run the follwoing:

```
export DOCKER_BUILD_PLATFORM=linux/arm64
export DOCKER_BUILD_ARCH=arm64
export ALPINE_IMAGE=arm64v8/alpine:3.14
export POSTGRES_IMAGE=arm64v8/postgres:13-alpine
export JDK_VERSION=17
```

Start all services:

```
docker-compose up -d
```

Let the ordergen service generate some orders and then stop the services:

```
docker-compose stop ordergen
```

