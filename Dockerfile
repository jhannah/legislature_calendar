FROM golang:1.17-alpine

RUN apk add --no-cache \
    gcc \
    musl-dev

COPY . /opt/legislative_server

WORKDIR /opt/legislative_server

ENTRYPOINT ["go", "run", "server.go"]
