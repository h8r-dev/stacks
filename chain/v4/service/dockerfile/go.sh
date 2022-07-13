#!/usr/bin/env bash

TEMP=/source/go.t
VALUES=/source/go.yaml
gomplate -f ${TEMP} -d values=${VALUES} -o Dockerfile
