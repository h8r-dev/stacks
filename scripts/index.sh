#!/usr/bin/env bash
# This script will generate index for official stacks

set -e

OFFICIAL_STACKS=$(find -s ./official-stack ! -name 'cue.mod' -maxdepth 1 -mindepth 1 -type d | cut -d ' ' -f 1)

mkdir -p idx
INDEX=idx/index

add_item() {
    STACK=$1

    NAME=$(yq '.name' $STACK)
    DESC=$(yq '.description' $STACK)
    VER=$(yq '.version' $STACK)

    yq -i '.stacks += {"name": "'"$NAME"'", "description": "'"$DESC"'", "version": "'"$VER"'", "url": "'"https://stack.h8r.io/$NAME-$VER.tar.gz"'"}' $2
}

generate() {
    echo > $1
    yq -i '.stacks[] += {}' $1
    for stack in $OFFICIAL_STACKS; do
        add_item $stack/metadata.yaml $1
    done
}

check() {
    TEMP=.tmp
    generate $TEMP
    yaml-diff $1 $TEMP
    rm $TEMP
}

usage() {
  echo "Usage:"
  echo "-g, --generate          Generate index file"
  echo "-c, --check             Check if the index is latest"
  echo "-h, --help              Show this usage page"
}

for option in "$@"; do
    case $option in
    -g|--generate)
        generate $INDEX
        ;;
    -c|--check)
        check $INDEX
        ;;
    -h|--help)
        usage
        exit 0
        ;;
    -*|--*)
        echo "Unknow option $option"
        exit 1
        ;;
    esac
done
