#!/usr/bin/env bash

git config --global user.email ${GIT_EMAIL}
git config --global user.name ${GIT_USER}
git checkout main
git add --all
test git commit --dry-run || exit 0
git commit -m "update hln workflow"
git push https://${GITHUB_TOKEN}@github.com/${GITHUB_ORGANIZATION}/${GITHUB_REPO}.git
