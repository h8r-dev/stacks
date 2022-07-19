#!/usr/bin/env bash

if [ "${FIRST}" == "true" ]; then
  REPO_URL=$(echo ${REPO_URL} | sed 's#://#://'${TOKEN}'@#')
  REPO_URL=$(echo ${REPO_URL}.git)
  git clone ${REPO_URL} ./
fi

# update env for deployment
if [ -n "${DEPLOYMENT_ENV}" ]; then
  echo "update env for ${NAME}"
  echo "${DEPLOYMENT_ENV}" > ex_env.yaml
  yq -i '.'${NAME}'.env = load("ex_env.yaml")' "${VALUE_PATH}"
  rm -rf ex_env.yaml
fi

# update ingress
if [ -n "${DEPLOYMENT_ENV}" ]; then
  echo "update ingress for ${NAME}"
  echo "${INGRESS_VALUE}" > ingress_value.yaml
  yq -i '.'${NAME}'.ingress = load("ingress_value.yaml")' "${VALUE_PATH}"
  rm -rf ingress_value.yaml
fi

if [ "${END}" == "true" ]; then
  git config user.name "forkmain"
  git config user.email "bot@forkmain.com"

  git add --all

  if [ -n "$(git status --porcelain)" ]; then
    echo "there are changes";
  else
    echo "no changes";
    exit 0
  fi

  git commit -m "forkmain: update values"
  echo "push to repo"
  git push origin main
fi
