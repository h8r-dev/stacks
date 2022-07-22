#!/usr/bin/env bash

TEMP=/source/nextjs.t
VALUES_FILE=/source/nextjs.yaml
gomplate -f ${TEMP} -d values=${VALUES_FILE} -o Dockerfile
