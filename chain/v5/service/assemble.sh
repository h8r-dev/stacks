#!/usr/bin/env bash

SOURCE_DIR="source/"
WORKFLOW_SRC="workflow/"
DOCKERFILE_SRC="dockerfile/"
WORKFLOW_DST="${SOURCE_DIR}.github/workflows/"
DOCKERFILE_DST="${SOURCE_DIR}.forkmain/"
mkdir -p ${WORKFLOW_DST}
mkdir -p ${DOCKERFILE_DST}
cp -r ${WORKFLOW_SRC}* ${WORKFLOW_DST}
cp -r ${DOCKERFILE_SRC}* ${DOCKERFILE_DST}
