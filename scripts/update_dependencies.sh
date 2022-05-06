#! /usr/bin/env bash

WORK_DIR=$(pwd)/

# Get all subdirs of current working dir.
ALL_SUB_DIRS_ARR=$(ls -d */ | cut -d ' ' -f 1)

# Get currently used Golang bin files install path (in GOPATH/bin, unless GOBIN is set)
GOBIN=$(go env GOBIN | tr -d '\n')
if [ -z "$GOBIN" ]; then
  GOBIN=$(go env GOPATH)/bin
fi

# hln bin files dir.
HLN_BIN_DIR=$HOME/.hln/bin

export PATH=$GOBIN:$HLN_BIN_DIR:$PATH

for sub_dir in $ALL_SUB_DIRS_ARR; do
  ABSOLUTE_SUB_DIR="${WORK_DIR}${sub_dir}"
  if [ -f "${ABSOLUTE_SUB_DIR}cue.mods" ]; then
    echo "Update dependencies for: $sub_dir"
    cd $ABSOLUTE_SUB_DIR
    hof mod vendor cue
    dagger project update
  fi
done
