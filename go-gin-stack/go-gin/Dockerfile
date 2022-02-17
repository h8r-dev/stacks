FROM golang:alpine as builder

ENV GOPROXY https://goproxy.cn,direct
WORKDIR /root
COPY . /root
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

FROM node:alpine as front-builder
WORKDIR /root
COPY ./front /root
RUN npm install && npm run build

FROM ubuntu:latest as prod
WORKDIR /root/
COPY --from=builder /root/app .
COPY --from=front-builder /root/dist ./front/dist

EXPOSE 8000
ENTRYPOINT ["/root/app"]
