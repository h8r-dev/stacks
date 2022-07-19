#!/usr/bin/env bash

printf '# deploy' > README.md
if [ -n "$STARTER" ]; then
  rm -rf "$HOME/.local/share/helm/starters/${STARTER_REPO_NAME}"
  git clone -b "$STARTER_REPO_VER" "$STARTER_REPO_URL" "$HOME/.local/share/helm/starters/${STARTER_REPO_NAME}"
  helm create "$NAME" -p "$STARTER"
else
  helm create "$NAME"
fi

if [ -n "$HELM_SET" ]; then
  set="yq -i $HELM_SET ${NAME}/values.yaml"
  eval "$set"
fi
# set domain
if [ -n "${DEPLOYMENT_ENV}" ]; then
echo "${INGRESS_VALUE}" > ingress_value.yaml
yq -i '.ingress = load("ingress_value.yaml")' "${NAME}/values.yaml"
rm -rf ingress_value.yaml
fi

# set image
# TODO: move set image pull secrets to #CreateImagePullSecret{}
yq -i '
  .image.repository = "'"${IMAGE_URL}"'" |
  .image.tag = "main" |
  .imagePullSecrets[0].name = "'"${APP_NAME}"'" |
  .image.pullPolicy = "IfNotPresent"
' "${NAME}/values.yaml"

# nocalhost config
if [ -f "${NAME}/conf/nocalhost.yaml" ] && [ -n "${GIT_URL}" ]; then
  echo "set nocalhost dev config for ${NAME}"
  yq -i '.nocalhost.gitUrl = "'"${GIT_URL}"'"' "${NAME}/values.yaml"
fi

# set env for deployment
if [ -n "${DEPLOYMENT_ENV}" ]; then
  echo "${DEPLOYMENT_ENV}" > ex_env.yaml
  yq -i '.env = load("ex_env.yaml")' "${NAME}/values.yaml"
  rm -rf ex_env.yaml
fi
