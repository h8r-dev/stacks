#!/usr/bin/env bash

printf '## :warning: DO NOT MAKE THIS REPOSITORY PUBLIC' > README.md
if [ ! -z "$STARTER" ]; then
  rm -rf $HOME/.local/share/helm/starters/${STARTER_REPO_NAME}
  git clone -b $STARTER_REPO_VER "$STARTER_REPO_URL" $HOME/.local/share/helm/starters/${STARTER_REPO_NAME}
  helm create $NAME -p $STARTER
else
  helm create $NAME
fi

# nocalhost dev config
if [ -f "${NAME}/conf/nocalhost.yaml" ]; then
  echo "set nocalhost dev config for ${NAME}"
  mkdir -p .nocalhost
  touch .nocalhost/config.yaml
  yq -i '.configProperties.version = "v2"' .nocalhost/config.yaml
  yq -i '.application.helmValues += [{"key": "'${NAME}.nocalhost.enabled'","value": true}]' .nocalhost/config.yaml
  # FixMe: hardcode
  git_url="https://github.com/${GIT_ORGANIZATION}/${NAME}"
  yq -i '.nocalhost.gitUrl = "'${git_url}'"' "${NAME}/values.yaml"
fi

if [ ! -z "$HELM_SET" ]; then
  set="yq -i $HELM_SET ${NAME}/values.yaml"
  eval $set
fi
# set domain
domain=http://$APP_NAME.$APPLICATION_DOMAIN
path=$INGRESS_HOST_PATH
if $REWRITE_INGRESS_HOST_PATH; then
  echo "set domain"
  path=$path"(/|$)(.*)"
  yq -i '.ingress.annotations += {"nginx.ingress.kubernetes.io/rewrite-target": "/$2"}' "${NAME}"/values.yaml
fi
# TODO RUNNING ROOT USERS IS UNSAFE
yq -i '.ingress.enabled = true | .ingress.className = "nginx" | .ingress.hosts[0].host="'$domain'" | .ingress.hosts[0].paths[0].path="'$path'" | .securityContext = {"runAsUser": 0}' "${NAME}"/values.yaml

# merge all charts
if $MERGE_ALL_CHARTS; then
  mkdir tmp
  helm create tmp/"$APP_NAME"
  # remove default template
  rm -rf tmp/"$APP_NAME"/templates/*
  # clean values.yaml
  :> tmp/"$APP_NAME"/values.yaml

  # move all charts to charts folder
  for file in */; do
    chartName=$(echo "$file" | tr -d '/')
    if [[ "$chartName" == "$APP_NAME" && "$NAME" != "$APP_NAME" ]] || [ "$chartName" == "tmp" ]; then
      continue
    fi
    echo "move $chartName"
    mv "$chartName" tmp/"$APP_NAME"/charts
  done
  echo "mv tmp file"
  mkdir "$APP_NAME"
  mv tmp/"$APP_NAME" .
  rm -rf tmp
  echo "$APP_NAME charts have:"
  ls "$APP_NAME"/charts
fi

# for output
mkdir -p /hln
touch /hln/output.yaml
url=$domain
if [ $INGRESS_HOST_PATH != "/" ]; then
  url=$domain$INGRESS_HOST_PATH
fi
yq -i '.services += [{"name": "'$NAME'", "url": "'$url'", "type": "'$REPOSITORY_TYPE'"}]' /hln/output.yaml
mkdir -p /h8r
printf $DIR_NAME > /h8r/application