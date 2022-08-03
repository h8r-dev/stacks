#!/usr/bin/env bash

TEMP=/source/frontend_cmd.t
VALUES_FILE=/source/frontend_cmd.yaml

yq -i '.buildCMD = strenv(BUILD_CMD)' ${VALUES_FILE}
yq -i '.outDir = strenv(OUT_DIR)' ${VALUES_FILE}
yq -i '.runCMD = strenv(RUN_CMD)' ${VALUES_FILE}
gomplate -f ${TEMP} -d values=${VALUES_FILE} -o Dockerfile
