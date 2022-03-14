FROM golang:alpine as builder

ENV GOPROXY https://goproxy.cn,direct
WORKDIR /root
COPY . /root
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .


FROM ubuntu:latest as prod
WORKDIR /root/
COPY --from=builder /root/app .

EXPOSE 8000
ENTRYPOINT ["/root/app"]
