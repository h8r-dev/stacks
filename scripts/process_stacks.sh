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

usage() {
  echo "Usage:"
  echo "-i, --install-deps      Install dependencies for stack"
  echo "-p, --package           Package all stack files into a '.tar.gz' format package"
  echo "-h, --help              Show this usage page"
}

# POSITIONAL_ARGS=()
# ARGS_COUNT=$#

for sub_dir in $ALL_SUB_DIRS_ARR; do
  ABSOLUTE_SUB_DIR="${WORK_DIR}${sub_dir}"
  if [ -f "${ABSOLUTE_SUB_DIR}/cue.mods" ]; then
    for option in "$@"; do
      case $1 in
        -i|--install-deps)
          install_dependencies $ABSOLUTE_SUB_DIR
          # shift
          ;;
        -p|--package)
          create_tars_dir
          pack $ABSOLUTE_SUB_DIR
          # shift
          ;;
        -h|--help)
          usage
          exit 0
          ;;
        -*|--*)
          echo "Unknow option $1"
          exit 1
          ;;
        # *)
        #   To Support handle multi command options
        #   POSITIONAL_ARGS+=("$1")
        #   shift
        #   ;;
      esac
    done

    # set -- "${POSITIONAL_ARGS[@]}" # Restore positional arguments
  fi
done
