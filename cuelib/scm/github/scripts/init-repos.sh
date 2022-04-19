#! /usr/bin/env bash

# ================================================= #
# A script to handle github repos
#
# Features:
#
#  1. Init repo
#  2. Set github action environment
#  3. Commit source code into remote repo
#
# ================================================= #

set -ex

# ================================================= #
# Prepare environment
# ================================================= #

# Store current working dir
WORKING_DIR=$(pwd)
GIT_REPO_ROOT_DIR=$WORKING_DIR/$SOURCECODEPATH
TERRAFORM_ROOT_DIR=$TERRAFORM_DIR
OUTPUT_FILE=$OUTPUT_FILE

# If you do not specify a Github organization,
# Terraform will create repos on the access token user's individual user account.
export GITHUB_OWNER=$ORGANIZATION
export GITHUB_TOKEN=$GITHUB_TOKEN

# Repo names
export REPO_NAME=$APPLICATION_NAME$SUFFIX
export BACKEND_NAME=$APPLICATION_NAME
export FRONTEND_NAME=$APPLICATION_NAME-front
export HELM_REPO_NAME=$APPLICATION_NAME-deploy

# Terraform variables
export TF_VAR_repo_name=$REPO_NAME
export TF_VAR_repo_visibility=$REPO_VISIBILITY
export TF_VAR_github_token=$GITHUB_TOKEN

# Repo urls
REPO_HTTP_URL=https://github.com/$ORGANIZATION/$REPO_NAME.git
REPO_AUTH_HTTP_URL=https://$ORGANIZATION:$GITHUB_TOKEN@github.com/$ORGANIZATION/$REPO_NAME.git
# REPO_SSH_URL=git@github.com:$ORGANIZATION/$REPO_NAME.git

# ================================================= #
# Modify repo files to match current config
# ================================================= #

cd $GIT_REPO_ROOT_DIR

# Update github action file
GITHUB_ACITON_FILE=./.github/workflows/docker-publish.yml
if [ -f $GITHUB_ACITON_FILE ] && [ $ISHELMCHART != "true" ]; then
  yq eval -i '.env.ORG = env(GITHUB_OWNER)' $GITHUB_ACITON_FILE
  yq eval -i '.env.HELM_REPO = env(HELM_REPO_NAME)' $GITHUB_ACITON_FILE
fi

# Update helm default values file
HELM_VALUES_FILE=/root/helm/values.yaml
if [ -f $HELM_VALUES_FILE ] && [ $ISHELMCHART == "true" ]; then
  yq eval -i '.image.repository = "ghcr.io/" + env(GITHUB_OWNER) + "/" + env(BACKEND_NAME)' $HELM_VALUES_FILE
  yq eval -i '.frontImage.repository = "ghcr.io/" + env(GITHUB_OWNER) + "/" + env(FRONTEND_NAME)' $HELM_VALUES_FILE
  yq eval -i '.nocalhost.backend.dev.gitUrl = "git@github.com:" + env(GITHUB_OWNER) + "/" + env(BACKEND_NAME) + ".git"' $HELM_VALUES_FILE
  yq eval -i '.nocalhost.frontend.dev.gitUrl = "git@github.com:" + env(GITHUB_OWNER) + "/" + env(FRONTEND_NAME) + ".git"' $HELM_VALUES_FILE
  yq eval -i '.ingress.hosts[0].path[0].serviceName = env(FRONTEND_NAME)' $HELM_VALUES_FILE
  yq eval -i '.ingress.hosts[0].path[1].serviceName = env(BACKEND_NAME)' $HELM_VALUES_FILE
fi

# Update helm chart file
HELM_CHART_FILE=/root/helm/Chart.yaml
if [ -f $HELM_CHART_FILE ] && [ $ISHELMCHART == "true" ]; then
  yq eval -i '.name = env(BACKEND_NAME)' $HELM_CHART_FILE
fi

# ================================================= #
# Create Repo
# ================================================= #

cd $TERRAFORM_ROOT_DIR

# Init terraform
terraform init

# Apply resources
terraform apply -auto-approve

# ================================================= #
# Commit source code files to remote repo.
# ================================================= #

cd $GIT_REPO_ROOT_DIR

# Init repo
git init && git remote add origin $REPO_AUTH_HTTP_URL

# Commit and push to remote repo
GIT_EMAIL=$(terraform output -state=$TERRAFORM_ROOT_DIR/terraform.tfstate -raw userEmail)
GIT_NAME=$(terraform output -state=$TERRAFORM_ROOT_DIR/terraform.tfstate -raw userFullName)
git add .
git config --global user.email $GIT_EMAIL
git config --global user.name $GIT_NAME
git commit -m 'init repo' --quiet
git branch -M main
git push -u origin main


# ================================================= #
# Summary
# ================================================= #

# Store repo url.
printf $REPO_HTTP_URL > $OUTPUT_FILE