#!/usr/bin/env bash

TEMP=/source/${BUILD_TOOL}.t
VALUES_FILE=/source/${BUILD_TOOL}.yaml

yq -i '.version = "'${VERSION}'"' ${VALUES_FILE}
gomplate -f ${TEMP} -d values=${VALUES_FILE} -o Dockerfile
