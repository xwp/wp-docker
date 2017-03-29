FROM alpine:3.5

RUN apk add --no-cache \
    bash \
    zip

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]