FROM golang:alpine

WORKDIR /go/src/archersaurus
COPY  archersaurus .
RUN go build

FROM alpine:latest  
RUN apk --no-cache add ca-certificates
COPY --from=0 /go/src/archersaurus/archersaurus /usr/local/bin
ENTRYPOINT ["/usr/local/bin/archersaurus"] 