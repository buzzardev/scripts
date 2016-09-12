FROM alpine

RUN apk add --update bash && rm -rf /var/cache/apk/*

COPY "./scripts/*.sh" "/scripts/"

COMMAND "/bin/bash"
