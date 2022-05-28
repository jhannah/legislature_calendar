FROM golang:1.18-alpine as build-env

RUN apk add --no-cache \
    gcc \
    musl-dev \
    ca-certificates

WORKDIR /go/src/app

COPY *.go .
COPY templates/ templates/

# go-sqlite3 requires CGO so we omit "CGO_ENABLED=0" and "-installsuffix cgo"
RUN go mod init && \
    go get -d -v ./... && \
    GOOS=linux go build -a -o /go/bin/app server.go

CMD ["/go/bin/app"]
