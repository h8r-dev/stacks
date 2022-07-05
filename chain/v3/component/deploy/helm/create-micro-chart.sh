#!/usr/bin/env bash

printf '# deploy' > README.md

helm create "$NAME"
