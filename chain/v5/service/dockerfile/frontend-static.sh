#!/usr/bin/env bash

TEMP=/source/frontend_static.t
VALUES_FILE=/source/frontend_static.yaml

yq -i '.buildCMD = strenv(BUILD_CMD)' ${VALUES_FILE}
yq -i '.outDir = strenv(OUT_DIR)' ${VALUES_FILE}
gomplate -f ${TEMP} -d values=${VALUES_FILE} -o Dockerfile

NGINX_CONF_TEMP=/source/static.conf.t
NGINX_CONF_VALUES_FILE=/source/static.conf.yaml

yq -i '.appType = strenv(APP_TYPE)' ${NGINX_CONF_VALUES_FILE}
yq -i '.path404 = strenv(PATH404)' ${NGINX_CONF_VALUES_FILE}
gomplate -f ${NGINX_CONF_TEMP} -d values=${NGINX_CONF_VALUES_FILE} -o nginx.conf