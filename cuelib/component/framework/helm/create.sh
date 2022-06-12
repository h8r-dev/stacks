#!/usr/bin/env bash

printf '# deploy' > README.md
if [ ! -z "$STARTER" ]; then
  rm -rf $HOME/.local/share/helm/starters/${STARTER_REPO_NAME}
  git clone -b $STARTER_REPO_VER "$STARTER_REPO_URL" $HOME/.local/share/helm/starters/${STARTER_REPO_NAME}
  helm create $NAME -p $STARTER
else
  helm create $NAME
fi

if [ ! -z "$HELM_SET" ]; then
  set="yq -i $HELM_SET ${NAME}/values.yaml"
  eval $set
fi
# set domain
domain=$APP_NAME.$APPLICATION_DOMAIN
path=$INGRESS_HOST_PATH
if $REWRITE_INGRESS_HOST_PATH; then
  echo "set domain"
  path=$path"(/|$)(.*)"
  yq -i '.ingress.annotations += {"nginx.ingress.kubernetes.io/rewrite-target": "/$2"}' "${NAME}"/values.yaml
fi
# TODO RUNNING ROOT USERS IS UNSAFE
yq -i '.ingress.enabled = true | .ingress.className = "nginx" | .ingress.hosts[0].host="'$domain'" | .ingress.hosts[0].paths[0].path="'$path'" | .securityContext = {"runAsUser": 0}' "${NAME}"/values.yaml
