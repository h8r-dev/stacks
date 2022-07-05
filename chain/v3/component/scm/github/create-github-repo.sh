#!/usr/bin/env bash

echo ${CONFIRM_PUSH}
if [ ! ${CONFIRM_PUSH} == "true" ]; then
	exit 0
fi
ls -lah /workdir/source/test10/charts/
exit 1

SOURCECODE_DIR=/workdir/source
TERRAFORM_DIR=/workdir/terraform

cd $SOURCECODE_DIR
git config --global init.defaultBranch $GIT_INIT_BRANCH
git config --global user.name $GIT_USER_NAME
git config --global user.email $GIT_USER_EMAIL
git init
git config remote.origin.url >&- || git remote add origin https://github.com/$GITHUB_ORGANIZATION/$REPOSITORY_NAME

info="$(gh repo list $GITHUB_ORGANIZATION --jq '.[] | select(.name=="'$REPOSITORY_NAME'")' --json name)"
if [ -z "$info" ]; then
	terraform -chdir=$TERRAFORM_DIR init -reconfigure -backend-config "secret_suffix=$TF_VAR_secret_suffix-$REPOSITORY_NAME" -backend-config "namespace=$TF_VAR_namespace" -backend-config "config_path=$HOME/.kube/config"
	terraform -chdir=$TERRAFORM_DIR apply --auto-approve -var "repo_name=$REPOSITORY_NAME" -var "repo_visibility=$VISIBILITY" -lock=false
fi

# wait 5 sec
sleep 5

# set remote url with PAT for git push
git remote set-url origin "https://$GITHUB_TOKEN@github.com/$GITHUB_ORGANIZATION/$REPOSITORY_NAME"

# git commit and push
git add .
git commit -m "init: heighliner stack"
git push -f origin main

# set remote origin without PAT
git remote set-url origin https://github.com/$GITHUB_ORGANIZATION/$REPOSITORY_NAME
