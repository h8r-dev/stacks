#!/usr/bin/env bash

TEMP=/source/gin.t
VALUES_FILE=/source/gin.yaml

yq -i '.version = strenv(VERSION)' ${VALUES_FILE}
yq -i '.entryFile = strenv(ENTRY_FILE)' ${VALUES_FILE}
gomplate -f ${TEMP} -d values=${VALUES_FILE} -o Dockerfile
