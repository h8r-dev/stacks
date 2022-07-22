#!/usr/bin/env bash

TEMP=/source/nextjs.t
VALUES=/source/nextjs.yaml
gomplate -f ${TEMP} -d values=${VALUES} -o Dockerfile
