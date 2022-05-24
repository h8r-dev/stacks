#! /usr/bin/env bash

WORK_DIR=$(pwd)/

# Get all subdirs of current working dir.
ALL_SUB_DIRS_ARR=$(find ./official-stack ! -name 'cue.mod' -maxdepth 1 -mindepth 1 -type d | cut -d ' ' -f 1)

# Get currently used Golang bin files install path (in GOPATH/bin, unless GOBIN is set)
GOBIN=$(go env GOBIN | tr -d '\n')
if [ -z "$GOBIN" ]; then
  GOBIN=$(go env GOPATH)/bin
fi

# hln bin files dir.
HLN_BIN_DIR=$HOME/.hln/bin

# index path
INDEX=idx/index

export PATH=$GOBIN:$HLN_BIN_DIR:$PATH

install_dependencies() {
  STACK_DIR=$1
  echo "Install dependencies for: $STACK_DIR"
  cd $STACK_DIR
  hof mod vendor cue
  dagger project update
}

create_tars_dir() {
  # Create tars dir to store all packages.
  [ ! -d './tars'  ] && mkdir -p tars
}

pack() {
  STACK_DIR=$1

  cd $WORK_DIR
  echo "Packing $STACK_DIR..."
  stackName=$(basename $STACK_DIR)
  dirName=$(dirname $STACK_DIR)
  tar -zcvf tars/$stackName-latest.tar.gz -C $dirName $stackName
}

add_index_item() {
    metadata=$2/metadata.yaml

    NAME=$(yq '.name' $metadata)
    DESC=$(yq '.description' $metadata)
    VER=$(yq '.version' $metadata)
    echo add $NAME
    yq -i '.stacks += {"name": "'"$NAME"'", "description": "'"$DESC"'", "version": "'"$VER"'", "url": "'"https://stack.h8r.io/$NAME-$VER.tar.gz"'"}' $1
}

check() {
    # This function is not ready
    TEMP=.tmp
    generate $TEMP
    yaml-diff $1 $TEMP
    rm $TEMP
}

initialize() {
  for option in "$@"; do
    case $option in
      -g|--generate)
        mkdir -p idx
        echo > $INDEX
        yq -i '.stacks[] += {}' $INDEX
        ;;
    esac
  done
}

usage() {
  echo "Usage:"
  echo "-i, --install-deps      Install dependencies for stack"
  echo "-p, --package           Package every stack into a '.tar.gz' format package"
  echo "-g, --generate          Generate index file"
  echo "-c, --check             Check if the index is latest"
  echo "-h, --help              Show this usage page"
}

initialize $1

for sub_dir in $ALL_SUB_DIRS_ARR; do
  ABSOLUTE_SUB_DIR="${WORK_DIR}${sub_dir}"
  if [ -f "${ABSOLUTE_SUB_DIR}/cue.mods" ]; then
    for option in "$@"; do
      case $option in
        -i|--install-deps)
          install_dependencies $ABSOLUTE_SUB_DIR
          ;;
        -p|--package)
          create_tars_dir
          pack $ABSOLUTE_SUB_DIR
          ;;
        -g|--generate)
          add_index_item $INDEX $ABSOLUTE_SUB_DIR
          ;;
        -c|--check)
          check $INDEX $ABSOLUTE_SUB_DIR
          ;;
        -h|--help)
          usage
          exit 0
          ;;
        -*|--*)
          echo "Unknown option $option"
          exit 1
          ;;
      esac
    done
  fi
done
