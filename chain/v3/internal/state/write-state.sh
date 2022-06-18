#!/usr/bin/env bash

CRD_SOURCE="https://github.com/h8r-dev/cloud-crd.git"
APPLICATION_FILE="config/samples/cloud_v1alpha1_application.yaml"
ENVIRONMENT_FILE="config/samples/cloud_v1alpha1_environment.yaml"
REPOSITORY_FILE="config/samples/cloud_v1alpha1_repository.yaml"

# ----------------------------------------------
#           Pull crd repository
# ----------------------------------------------

git clone ${CRD_SOURCE} crd
cd crd
cat $APPLICATION_FILE
cat $ENVIRONMENT_FILE
cat $REPOSITORY_FILE
