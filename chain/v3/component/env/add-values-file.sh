#!/usr/bin/env bash
DOMAIN=$ENV_NAME.$APP_NAME.$DOMAIN
DEPLOY_NAME=$APP_NAME"-deploy"
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
    git checkout -b $ENV_NAME
fi
echo 'env exists'

COMMIT_TAG="$(git rev-parse --short HEAD | tr -d '\n')"

cd /workdir/$DEPLOY_NAME/$APP_NAME

# check if values.yaml file exist
# if [ -e env/$ENV_NAME/values.yaml ] && [ "$ENV_NAME" != "main" ]
# then
#     echo "values.yaml exists, skip"
#     exit
# fi

# Env not exist, create values.yaml file
mkdir -p env/$ENV_NAME/ && touch env/$ENV_NAME/values.yaml
envName=$REPOSITORY_NAME yq -i '
.[strenv(envName)] += {
    "image": {"tag": "'$COMMIT_TAG'"},
    "ingress": {"hosts": [{"host": "'$DOMAIN'", "paths": [{"path": "/", "pathType": "ImplementationSpecific"}]}]}
}
' env/$ENV_NAME/values.yaml