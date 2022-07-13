#!/usr/bin/env bash

git config user.name "forkmain"
git config user.email "bot@forkmain.com"

git add --all

git commit -m "forkmain: set up this repo"
git remote add forkmain-origin https://${TOKEN}@github.com/${ORGANIZATION}/${NAME}.git
git push forkmain-origin main
