#!/usr/bin/env bash

if [ ! -d "$REPOSITORY_NAME" ]; then
  git clone https://$GITHUB_TOKEN@github.com/$GITHUB_ORGANIZATION/$REPOSITORY_NAME
fi

if [ ! -d "$DEPLOY_NAME" ]; then
  git clone https://$GITHUB_TOKEN@github.com/$GITHUB_ORGANIZATION/$DEPLOY_NAME
fi

cd /workdir/$REPOSITORY_NAME
# check branch=env exsit
existed_in_remote=$(git ls-remote --heads origin ${ENV_NAME})
if [[  -z ${existed_in_remote} ]]; then
    echo 'env not exists'
    git checkout -b $ENV_NAME origin/$FROM_BRANCH
fi

COMMIT_TAG="$(git rev-parse --short HEAD | tr -d '\n')"

cd /workdir/$DEPLOY_NAME/$APP_NAME

# Add env values.yaml file and set values
#mkdir -p env/$ENV_NAME/ && touch env/$ENV_NAME/values.yaml
mkdir -p env/$ENV_NAME/

# check first, if values.yaml file exist, delete it and recreate values.yaml file, each service will do this job by foreach, so just check first foreach step.
if [[ -f env/$ENV_NAME/values.yaml && "$FIRST" == "true" ]]; then
  rm env/$ENV_NAME/values.yaml
fi

# copy values to env values
if [[ ! -f env/$ENV_NAME/values.yaml ]]; then
  cp values.yaml env/$ENV_NAME/values.yaml
fi

# envName=$REPOSITORY_NAME yq -i '
# .[strenv(envName)] += {
#     "image": {"tag": "'$COMMIT_TAG'"},
#     "ingress": {"hosts": [{"host": "'$DOMAIN'", "paths": [{"path": "/", "pathType": "ImplementationSpecific"}]}]}
# }
# ' env/$ENV_NAME/values.yaml

# patch image tag
envName=$REPOSITORY_NAME yq -i '
.[strenv(envName)].image.tag = "'$COMMIT_TAG'"
' env/$ENV_NAME/values.yaml

# patch ingress
envName=$REPOSITORY_NAME yq -i '
.[strenv(envName)].ingress.hosts[0].host = "'$DOMAIN'"
' env/$ENV_NAME/values.yaml

# set env into values.yaml
if [[ -f /env.yaml ]]; then
    envName=$REPOSITORY_NAME yq -i '
    .[strenv(envName)].env = load("../../../env.yaml")
    ' env/$ENV_NAME/values.yaml
fi

# set extra into values.yaml
if [[ -f /extra.yaml ]]; then
    envName=$REPOSITORY_NAME yq -i '
    .[strenv(envName)] += load("../../../extra.yaml")
    ' env/$ENV_NAME/values.yaml
fi