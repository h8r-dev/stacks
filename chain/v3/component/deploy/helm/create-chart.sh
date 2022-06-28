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
domain=$APPLICATION_DOMAIN
path=$INGRESS_HOST_PATH
if $REWRITE_INGRESS_HOST_PATH; then
  path=$path"(/|$)(.*)"
  yq -i '.ingress.annotations += {"nginx.ingress.kubernetes.io/rewrite-target": "/$2"}' "${NAME}"/values.yaml
fi
# TODO RUNNING ROOT USERS IS UNSAFE
# set domain
yq -i '.ingress.enabled = true | .ingress.className = "nginx" | .ingress.hosts[0].host="'$domain'" | .ingress.hosts[0].paths[0].path="'$path'" | .securityContext = {"runAsUser": 0}' "${NAME}/values.yaml"

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