#! /usr/bin/env bash

set -ex

# Update dependencies for gin-next stack
cd ./gin-next
hof mod vendor cue && dagger project update

# Update dependencies for gin-vue stack
cd .. && cd ./gin-vue
hof mod vendor cue && dagger project update
