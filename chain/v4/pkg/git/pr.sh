#!/usr/bin/env bash

git config user.name "forkmain"
git config user.email "bot@forkmain.com"

git add -f .github
git add -f .forkmain

if [ -n "$(git status --porcelain)" ]; then
  echo "there are changes";
else
  echo "no changes";
  exit 0
fi

git commit -m "forkmain: set up this repo"
branch=forkmain-$(head /dev/urandom | tr -dc a-z | head -c 6)
git checkout -b $branch
git push origin $branch:$branch
gh pr create --title "forkmain: set up this repo" --body "set up this repo by forkmain"
