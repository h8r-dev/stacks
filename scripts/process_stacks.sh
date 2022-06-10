#! /usr/bin/env bash

PACK_TARGET=$PWD/tars
INDEX_DIR=$PWD/tars
INDEX_SUFFIX=index.yaml
INDEX_FILE=$INDEX_DIR/$INDEX_SUFFIX
META_SUFFIX=metadata.yaml

GOBIN=$(go env GOBIN | tr -d '\n')
if [ -z "$GOBIN" ]; then
  GOBIN=$(go env GOPATH)/bin
fi
HLN_BIN_DIR=$HOME/.hln/bin
export PATH=$GOBIN:$HLN_BIN_DIR:$PATH

walkStacks() {
  VISIT_FUNC=$1
  SUB_DIRS=$(find $PWD -maxdepth 2 -type d)
  for SUB_DIR in $SUB_DIRS; do
    if [ -d "$SUB_DIR/plans" ]; then
      $VISIT_FUNC $SUB_DIR
    fi
  done
}

installDependencies() {
  STACK_DIR=$1

  WORK_DIR=$PWD
  echo "Installing dependencies for: $STACK_DIR..."
  cd $STACK_DIR
  hof mod vendor cue
  # dagger project update
  cd $WORK_DIR
}

installAllDeps() {
  walkStacks installDependencies
}

packStack() {
  STACK_DIR=$1

  echo "Packing $STACK_DIR..."
  mkdir -p $PACK_TARGET

  PARENT_DIR=$(dirname $STACK_DIR)
  STACK_NAME=$(basename $STACK_DIR)

  META_FILE=$STACK_DIR/$META_SUFFIX
  VERSION=$(yq '.version' $META_FILE) # require yq installed
  
  TAR_NAME_VERSIONED=$STACK_NAME-$VERSION.tar.gz
  TAR_NAME_LATEST=$STACK_NAME-latest.tar.gz
  
  # for particular version
  tar -zcvf $PACK_TARGET/$TAR_NAME_VERSIONED -C $PARENT_DIR $STACK_NAME
  # for latest version
  cp $PACK_TARGET/$TAR_NAME_VERSIONED $PACK_TARGET/$TAR_NAME_LATEST
}

packAllStacks() {
  mkdir -p $PACK_TARGET
  walkStacks packStack
}

addIndexEntry() {
  STACK_DIR=$1

  mkdir -p $INDEX_DIR

  BASE_URL=https://stack.h8r.io
  META_FILE=$STACK_DIR/$META_SUFFIX
  
  NAME=$(yq '.name' $META_FILE)
  DESC=$(yq '.description' $META_FILE)
  VERSION=$(yq '.version' $META_FILE)
  URL=$BASE_URL/$NAME-$VERSION.tar.gz

  yq -i '.stacks += {"name": "'"$NAME"'", "description": "'"$DESC"'", "version": "'"$VERSION"'", "url": "'"$URL"'"}' $INDEX_FILE
}

updateIndex() {
  mkdir -p $INDEX_DIR
  echo 'stacks: []' > $INDEX_FILE
  walkStacks addIndexEntry
}

evalStack() {
  STACK_DIR=$1
  cd $STACK_DIR && cue eval ./plans > /dev/null
}

# Run `cue eval` to check all stacks
evalAllStack() {
  walkStacks evalStack
}

usage() {
  echo "Usage:"
  echo "-i, --install-deps      Install dependencies for stacks"
  echo "-p, --pack              Compress all stacks"
  echo "-u, --update-index      Update index file"
  echo "-c, --check             Check if the index is latest"
  echo "-h, --help              Show this usage page"
}

# Execute target function according to args
for option in "$@"; do
  case $option in
    -i|--install-deps)
      installAllDeps
      ;;
    -p|--pack)
      packAllStacks
      ;;
    -u|--update-index)
      updateIndex
      ;;
    -c|--check-index)
      echo unimplemented
      ;;
    -e|--eval)
      evalAllStack
      ;;
    -h|--help)
      usage
      ;;
    -*|--*)
      echo "Unknown option $option"
      exit 1
      ;;
  esac
done
