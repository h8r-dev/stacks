#! /bin/bash

set -x

cd $1
mkdir -p cue.mod/pkg/github.com/h8r-dev/stacks/
cp -r ../cuelib cue.mod/pkg/github.com/h8r-dev/stacks/cuelib
cp -r ../chain cue.mod/pkg/github.com/h8r-dev/stacks/chain
cp -r ../chain cue.mod/pkg/github.com/h8r-dev/chain
dagger project update
