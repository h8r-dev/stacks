#! /usr/bin/env bash

WORK_DIR=$(pwd)/

# Get all subdirs of current working dir.
ALL_SUB_DIRS_ARR=$(find ./official-stack -maxdepth 1 -mindepth 1 -type d | cut -d ' ' -f 1)

# Get currently used Golang bin files install path (in GOPATH/bin, unless GOBIN is set)
GOBIN=$(go env GOBIN | tr -d '\n')
if [ -z "$GOBIN" ]; then
  GOBIN=$(go env GOPATH)/bin
fi

# hln bin files dir.
HLN_BIN_DIR=$HOME/.hln/bin

export PATH=$GOBIN:$HLN_BIN_DIR:$PATH

update_dependencies() {
  STACK_DIR=$1
  echo "Update dependencies for: $STACK_DIR"
  cd $STACK_DIR
  hof mod vendor cue
  dagger project update
}

# package() {
#   # tar\c
# }

for sub_dir in $ALL_SUB_DIRS_ARR; do
  ABSOLUTE_SUB_DIR="${WORK_DIR}${sub_dir}"
  if [ -f "${ABSOLUTE_SUB_DIR}/cue.mods" ]; then
    update_dependencies $ABSOLUTE_SUB_DIR
  fi
done
