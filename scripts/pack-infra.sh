#!/usr/bin/env bash

export WORKDIR="$PWD"
export INFRA_DIR="./infra"
export INFRA_DST="./tars"

export GOBIN="$(go env GOBIN | tr -d '\n')"
if [ -z "$GOBIN" ]; then
  export GOBIN="$(go env GOPATH)/bin"
fi
export HLN_BIN_DIR="$HOME/.hln/bin"
export PATH="$GOBIN:$HLN_BIN_DIR:$PATH"

cd $INFRA_DIR
hof mod vendor cue

cd $WORKDIR
mkdir $INFRA_DST
tar czf "$INFRA_DST/infra.tar.gz" "$INFRA_DIR"
