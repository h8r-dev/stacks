#!/usr/bin/env bash

TEMP=/source/gin.t
VALUES_FILE=/source/gin.yaml

yq -i '.version = strenv(VERSION)' ${VALUES_FILE}
yq -i '.buildCMD = strenv(BUILD_CMD)' ${VALUES_FILE}
yq -i '.runCMD = strenv(RUN_CMD)' ${VALUES_FILE}
gomplate -f ${TEMP} -d values=${VALUES_FILE} -o Dockerfile
