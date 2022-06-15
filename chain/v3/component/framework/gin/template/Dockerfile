FROM golang:alpine as builder

RUN apk add git

WORKDIR /root
COPY . /root
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

# TODO change to distroless
FROM ubuntu:latest as prod
WORKDIR /root/
COPY --from=builder /root/app .
COPY --from=builder /root/config.ini .
RUN apt-get update && apt-get install -y --no-install-recommends stress-ng \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 8000
ENTRYPOINT ["/root/app"]
