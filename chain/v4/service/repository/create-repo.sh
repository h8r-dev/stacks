#!/usr/bin/env bash

if [ $(gh repo view ${ORGANIZATION}/${NAME} --json name -q '.name') ]; then
  exit 0
fi

gh repo create ${ORGANIZATION}/${NAME} --${VISIBILITY}
