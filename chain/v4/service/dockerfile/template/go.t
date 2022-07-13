# syntax=docker/dockerfile:1

##
## Build
##
FROM golang:{{ (datasource "values").version }} AS build

WORKDIR /workdir

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY ./ ./

RUN go build -o /app {{ (datasource "values").pkg }}

##
## Deploy
##
FROM gcr.io/distroless/base-debian11

WORKDIR /

COPY --from=build /app /app

EXPOSE 8080

USER nonroot:nonroot

ENTRYPOINT ["/app"]