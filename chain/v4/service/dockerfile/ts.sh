#!/usr/bin/env bash

TEMP=/source/ts.t
VALUES=/source/ts.yaml
gomplate -f ${TEMP} -d values=${VALUES} -o Dockerfile
