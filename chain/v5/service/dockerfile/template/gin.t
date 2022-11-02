# syntax=docker/dockerfile:1

FROM golang:{{ (datasource "values").version }}

WORKDIR /workdir

COPY ./ ./

RUN go mod download

RUN {{ (datasource "values").buildCMD }}

CMD {{ (datasource "values").runCMD }}
