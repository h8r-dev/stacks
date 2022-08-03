#!/usr/bin/env bash

DIR=$(echo ${REMOTE##*/})
REMOTE=$(echo ${REMOTE} | sed 's/:\/\/git/:\/\/'${TOKEN}'@git/')
REMOTE=$(echo ${REMOTE}.git)
git clone ${REMOTE}
mv $DIR source
